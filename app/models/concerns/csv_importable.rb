# frozen_string_literal: true

module CSVImportable
  extend ActiveSupport::Concern

  included do
    attr_accessor :csv_is_malformed, :data, :rows

    encrypts :csv_data

    belongs_to :team

    belongs_to :uploaded_by,
               class_name: "User",
               foreign_key: :uploaded_by_user_id

    has_and_belongs_to_many :patients

    scope :csv_not_removed, -> { where(csv_removed_at: nil) }
    scope :processed, -> { where.not(processed_at: nil) }

    enum :status,
         {
           pending_import: 0,
           rows_are_invalid: 1,
           processed: 2,
           low_pds_match_rate: 3,
           changesets_are_invalid: 4
         },
         default: :pending_import,
         validate: true

    validates :csv,
              absence: {
                if: :csv_removed?
              },
              presence: {
                unless: :csv_removed?
              }
    validates :csv_filename, presence: true

    validate :csv_is_valid
    validate :csv_has_records
    validate :rows_are_valid

    before_save :ensure_processed_with_count_statistics
  end

  def csv=(file)
    self.csv_data = remove_bom_if_present(file&.read)
    self.csv_filename = file&.original_filename
  end

  # CSV files exported from Excel may have a BOM.
  # https://en.wikipedia.org/wiki/Byte_order_mark
  # e.g. if you create a new class import from scratch in Excel on Mac v16,
  # save the file as CSV, and upload it.
  def remove_bom_if_present(data)
    StringIO.new(data).tap(&:set_encoding_by_bom).read
  end

  # Needed so that validations match the form field name.
  def csv
    csv_data
  end

  def csv_removed?
    csv_removed_at != nil
  end

  def load_data!
    return if invalid?

    self.data ||= CSVParser.call(csv_data)
    self.rows_count = data.count
  rescue CSV::MalformedCSVError
    self.csv_is_malformed = true
  end

  def parse_rows!
    load_data! if data.nil?
    return if invalid?

    self.rows =
      remove_trailing_blank_rows(data).map { |row_data| parse_row(row_data) }

    if invalid?
      self.serialized_errors = errors.to_hash
      self.status = :rows_are_invalid
      save!(validate: false)
    end
  end

  def remove_trailing_blank_rows(table)
    found_values = false

    # map(&:itself) because CSV::Table doesn't have a reverse method
    rows_in_reverse_order = table.map(&:itself).reverse

    filtered_rows =
      rows_in_reverse_order.select do |row|
        if found_values
          true
        elsif row.fields.all?(&:blank?)
          false
        else
          found_values = true
          true
        end
      end

    filtered_rows.reverse
  end

  COUNT_COLUMNS = %i[
    new_record_count
    changed_record_count
    exact_duplicate_record_count
  ].freeze

  def processed?
    processed_at != nil
  end

  def process!
    return if processed?

    parse_rows! if rows.nil?
    return if invalid?

    if is_a?(PatientImport)
      process_patient_import!
    else
      process_immunisation_import!
    end
  end

  def process_patient_import!
    changesets =
      rows.each_with_index.map do |row, row_number|
        PatientChangeset.from_import_row(row:, import: self, row_number:)
      end

    if Flipper.enabled?(:import_search_pds)
      process_no_postcode_changesets(self.changesets.without_postcode)
      if self.changesets.with_postcode.any?
        enqueue_pds_cascading_searches(self.changesets.with_postcode)
        return
      end
    end

    changesets.each do |patient_changeset|
      patient_changeset.assign_patient_id
      patient_changeset.processed!
    end

    validate_changeset_uniqueness!
    return if changesets_are_invalid?

    CommitImportJob.perform_async(to_global_id.to_s)
  end

  def process_immunisation_import!
    counts = COUNT_COLUMNS.index_with(0)

    ActiveRecord::Base.transaction do
      rows.each do |row|
        count_column_to_increment = process_row(row)
        counts[count_column_to_increment] += 1
        bulk_import(rows: 100)
      end

      bulk_import(rows: :all)

      postprocess_rows!

      update_columns(processed_at: Time.zone.now, status: :processed, **counts)
    end

    post_commit!
    UpdatePatientsFromPDS.call(patients, queue: :imports)
  end

  def process_no_postcode_changesets(changesets)
    changesets.find_each do |cs|
      cs.search_results << {
        step: :no_fuzzy_with_history,
        result: :no_postcode,
        nhs_number: nil,
        created_at: Time.current
      }

      cs.processed!
    end
  end

  def enqueue_pds_cascading_searches(changesets)
    changesets.find_each do |cs|
      PDSCascadingSearchJob.set(queue: :imports).perform_later(
        cs,
        queue: :imports
      )
    end
  end

  def remove!
    return if csv_removed?
    update!(csv_data: nil, csv_removed_at: Time.zone.now)
  end

  def load_serialized_errors!
    return if serialized_errors.blank?

    serialized_errors.each do |attribute, messages|
      messages.each { errors.add(attribute, _1) }
    end
  end

  def csv_is_valid
    return unless csv_is_malformed

    errors.add(:csv, :invalid)
  end

  def csv_has_records
    return unless data

    errors.add(:csv, :empty) if data.empty?
  end

  def rows_are_valid
    return unless rows

    rows.each(&:validate)

    check_rows_are_unique

    rows.each.with_index do |row, index|
      next if row.errors.empty?

      # The first row is the header and the index is 0-based, so we add two
      # to match what the user sees in the spreadsheet

      formatted_errors =
        row.errors.map do |error|
          if error.attribute == :base
            error.message
          else
            "<code>#{error.attribute}</code>: #{error.message}"
          end
        end

      errors.add("row_#{index + 2}".to_sym, formatted_errors)
    end
  end

  def ensure_processed_with_count_statistics
    if processed? && COUNT_COLUMNS.any? { |column| send(column).nil? }
      raise "Count statistics must be set for a processed import."
    elsif !processed? && COUNT_COLUMNS.any? { |column| !send(column).nil? }
      raise "Count statistics must not be set for a non-processed import."
    end
  end

  def join_table_class(import_type, record_type)
    Class.new(ApplicationRecord) do
      @import_type = import_type.to_s.pluralize
      @record_type = record_type.to_s

      self.table_name = [@import_type, @record_type.pluralize].sort.join("_")

      def self.model_name
        ActiveModel::Name.new(
          self,
          nil,
          [@import_type.camelize, @record_type.singularize.camelize].sort.join
        )
      end
    end
  end

  def link_records_by_type(type, records)
    import_type = self.class.name.underscore
    type = type.to_s

    join_table_class(import_type, type).import(
      ["#{type.singularize}_id", "#{import_type}_id"],
      records.map(&:id).product([id]).uniq,
      on_duplicate_key_ignore: true
    )
  end

  def remaining_time
    rows_per_second = 30.0 # 2024/10/10: Based on a 1000 row upload on test env.
    total_seconds = rows_count / rows_per_second
    elapsed_seconds = Time.current - created_at
    remaining_seconds = [total_seconds - elapsed_seconds, 0].max.round

    hours, remaining = remaining_seconds.divmod(3600)
    minutes, = remaining.divmod(60)

    if hours.positive?
      "#{hours} hour#{"s" if hours != 1} #{minutes} minute#{"s" if minutes != 1} remaining"
    elsif minutes.positive?
      "#{minutes} minute#{"s" if minutes != 1} remaining"
    else
      "Less than 1 minute remaining"
    end
  end
end
