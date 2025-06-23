# frozen_string_literal: true

require "yaml"
require "concurrent"
require_relative "fake_data_generators"

class PIIAnonymizer
  # Custom exceptions for better error handling
  class AnonymizationError < StandardError
  end
  class ConfigurationError < StandardError
  end
  class RetryLimitExceededError < StandardError
  end

  attr_reader :config, :progress_callback, :dry_run

  # Maximum number of retries for database constraint violations
  MAX_RETRIES = 10

  def initialize(config_path: nil, dry_run: false, progress_callback: nil)
    @config_path = config_path || default_config_path
    @config = load_config
    @dry_run = dry_run
    @progress_callback = progress_callback
  end

  def anonymize_all!
    validate_environment!
    create_backup! if config.dig("backup", "required") && !dry_run

    log_info "Starting PII anonymization process (dry_run: #{dry_run})"

    processing_order = config.dig("processing", "processing_order") || []

    processing_order.each do |information_type|
      if information_type == "audits"
        anonymize_audit_tables!
      else
        anonymize_information_type!(information_type)
      end
    end

    log_info "PII anonymization completed successfully"
  end

  private

  def default_config_path
    Rails.root.join("config/pii_anonymization.yml")
  end

  def load_config
    unless File.exist?(@config_path)
      raise ConfigurationError, "Configuration file not found: #{@config_path}"
    end

    YAML.load_file(@config_path)
  rescue Psych::SyntaxError => e
    raise ConfigurationError, "Invalid YAML in configuration file: #{e.message}"
  end

  def validate_environment!
    unless Rails.env.development? || Rails.env.test?
      raise AnonymizationError,
            "PII anonymization can only be run in development or test environments"
    end

    if Rails.env.production?
      raise AnonymizationError, "PII anonymization cannot be run in production"
    end
  end

  def create_backup!
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_tables = config.dig("backup", "tables_to_backup") || []

    backup_tables.each do |table_name|
      backup_table_name = "#{table_name}_backup_#{timestamp}"

      log_info "Creating backup: #{table_name} -> #{backup_table_name}"

      next if dry_run
      ActiveRecord::Base.connection.execute(
        "CREATE TABLE #{backup_table_name} AS SELECT * FROM #{table_name}"
      )
    end
  end

  def anonymize_information_type!(information_type)
    type_config = config.dig("information_types", information_type)
    unless type_config
      raise ConfigurationError,
            "No configuration found for information type: #{information_type}"
    end

    log_info "Processing information type: #{information_type}"
    log_info "Description: #{type_config["description"]}"

    primary_table = type_config["primary_table"]
    batch_size =
      type_config["batch_size"] ||
        config.dig("processing", "default_batch_size") || 1000
    parallel_threads = config.dig("processing", "parallel_threads") || 4

    # Get total count for progress tracking
    total_records = get_table_count(primary_table)
    log_info "Total #{primary_table} records: #{total_records}, batch size: #{batch_size}, threads: #{parallel_threads}"

    # Create batches for parallel processing
    batches = []
    (0...total_records).step(batch_size) do |offset|
      batch_end = [offset + batch_size - 1, total_records - 1].min
      batches << {
        offset: offset,
        size: batch_size,
        range: "#{offset + 1}-#{batch_end + 1}"
      }
    end

    # Process batches in parallel using thread pool
    processed_count = Concurrent::AtomicFixnum.new(0)

    thread_pool = Concurrent::FixedThreadPool.new(parallel_threads)
    futures =
      batches.map do |batch|
        Concurrent::Future.execute(executor: thread_pool) do
          process_batch_with_retry(
            type_config,
            batch,
            processed_count,
            total_records,
            information_type
          )
        end
      end

    # Wait for all batches to complete
    futures.each(&:wait!)

    # Check for any failures
    failures = futures.select(&:rejected?)
    unless failures.empty?
      error_messages = failures.map { |f| f.reason.message }.join("; ")
      raise AnonymizationError, "Batch processing failed: #{error_messages}"
    end

    thread_pool.shutdown
    thread_pool.wait_for_termination(30) # Wait up to 30 seconds for clean shutdown
  end

  def process_batch_with_retry(
    type_config,
    batch,
    processed_count,
    total_records,
    information_type
  )
    retries = 0
    max_retries = MAX_RETRIES

    begin
      log_info "Processing batch: #{batch[:range]} (Thread: #{Thread.current.object_id})"

      process_information_batch!(type_config, batch[:offset], batch[:size])

      # Update progress atomically
      current_count = processed_count.increment(batch[:size])
      report_progress(information_type, current_count, total_records)
    rescue ActiveRecord::RecordNotUnique => e
      retries += 1
      if retries <= max_retries
        # Exponential backoff with jitter to reduce collision probability
        sleep_time = 0.1 * (2**retries) + rand(0.1)
        log_info "Batch #{batch[:range]} failed with unique constraint violation, retrying in
#{sleep_time.round(2)}s (attempt #{retries}/#{max_retries})"
        sleep(sleep_time)
        retry
      else
        raise RetryLimitExceededError,
              "Batch #{batch[:range]} failed after #{max_retries} retries: #{e.message}"
      end
    end
  end

  def process_information_batch!(type_config, offset, batch_size)
    return if dry_run

    # Use a transaction to ensure all related tables are updated together
    # This implements our batch-by-information-type strategy
    # Each thread gets its own database connection from the connection pool
    ActiveRecord::Base.transaction do
      type_config["tables"].each do |table_name, table_config|
        process_table_in_batch!(
          table_name,
          table_config,
          type_config,
          offset,
          batch_size
        )
      end
    end
  end

  def process_table_in_batch!(
    table_name,
    table_config,
    type_config,
    offset,
    batch_size
  )
    batch_strategy = table_config["batch_strategy"] || "related_records"

    case batch_strategy
    when "all_records"
      # Process all records in this table for each batch
      process_all_records_in_table!(table_name, table_config)
    else
      # Process records related to the primary table batch
      process_related_records_in_table!(
        table_name,
        table_config,
        type_config,
        offset,
        batch_size
      )
    end
  end

  def process_all_records_in_table!(table_name, table_config)
    # For tables without direct relationships, update all records
    updates = build_field_updates(table_config["fields"])
    return if updates.empty?

    update_sql = build_update_sql(table_name, updates)
    log_info "Executing SQL: #{update_sql}" if dry_run

    ActiveRecord::Base.connection.execute(update_sql) unless dry_run
  end

  def process_related_records_in_table!(
    table_name,
    table_config,
    type_config,
    offset,
    batch_size
  )
    # For tables with relationships, update records in the current batch range
    primary_table = type_config["primary_table"]
    primary_key = type_config["primary_key"] || "id"

    updates = build_field_updates(table_config["fields"])
    return if updates.empty?

    # Build SQL to update records in the current batch
    where_clause = if table_name == primary_table
      # Update the primary table records directly
      "#{primary_key} IN
(SELECT #{primary_key} FROM #{table_name} ORDER BY #{primary_key} LIMIT #{batch_size} OFFSET #{offset})"
    else
      # Update all records in related tables (since we're processing by information type)
      "1=1" # Update all records
                   end

    update_sql = build_update_sql(table_name, updates, where_clause)
    log_info "Executing SQL: #{update_sql}" if dry_run

    ActiveRecord::Base.connection.execute(update_sql) unless dry_run
  end

  def build_field_updates(fields_config)
    updates = {}

    fields_config.each do |field_name, field_config|
      fake_value = generate_fake_value(field_config)
      updates[field_name] = fake_value
    end

    updates
  end

  def build_update_sql(table_name, updates, where_clause = "1=1")
    set_clauses =
      updates
        .map { |field, value|
          quoted_value = ActiveRecord::Base.connection.quote(value)
          "#{field} = #{quoted_value}"
        }
        .join(", ")

    "UPDATE #{table_name} SET #{set_clauses} WHERE #{where_clause}"
  end

  def generate_fake_value(field_config)
    faker_method = field_config["faker_method"]
    FakeDataGenerators.call_faker_method(faker_method)
  end

  def report_progress(information_type, processed, total)
    percentage = (processed.to_f / total * 100).round(1)
    log_info "#{information_type}: #{processed}/#{total} (#{percentage}%)"

    @progress_callback&.call(information_type, processed, total)
  end

  def anonymize_audit_tables!
    # TODO: Implement audit table anonymization for JSONB columns
    log_info "Audit table anonymization not yet implemented"
  end

  def get_table_count(table_name)
    ActiveRecord::Base.connection.select_value(
      "SELECT COUNT(*) FROM #{table_name}"
    )
  end

  def log_info(message)
    # Thread-safe logging with thread ID for debugging
    thread_id = Thread.current.object_id.to_s(16)[-4..] # Last 4 chars of thread ID
    timestamped_message =
      "[#{Time.current.strftime("%H:%M:%S")}][#{thread_id}] #{message}"

    Rails.logger.info("[PIIAnonymizer] #{timestamped_message}")
    if Rails.env.development?
      Rails.logger.debug "[PIIAnonymizer] #{timestamped_message}"
    end
  end
end
