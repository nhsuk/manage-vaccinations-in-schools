# frozen_string_literal: true

module CSVImportable
  extend ActiveSupport::Concern

  include Recordable

  included do
    attr_accessor :csv_is_malformed, :data, :rows

    encrypts :csv_data

    belongs_to :team

    belongs_to :uploaded_by,
               class_name: "User",
               foreign_key: :uploaded_by_user_id

    has_and_belongs_to_many :patients

    scope :csv_not_removed, -> { where(csv_removed_at: nil) }

    enum :status,
         %i[pending_import rows_are_invalid recorded],
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
    validate :headers_are_valid
    validate :rows_are_valid

    before_save :ensure_recorded_with_count_statistics
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

  def slow?
    rows_count > 15
  end

  def load_data!
    return if invalid?

    self.data ||= CSV.parse(csv_data, headers: true, skip_blanks: true)
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

  def record!
    return if recorded?

    parse_rows! if rows.nil?
    return if invalid?

    counts = count_columns.index_with(0)

    ActiveRecord::Base.transaction do
      rows.each do |row|
        count_column_to_increment = process_row(row)
        counts[count_column_to_increment] += 1
        bulk_import(rows: 100)
      end

      bulk_import(rows: :all)

      postprocess_rows!

      update_columns(recorded_at: Time.zone.now, status: :recorded, **counts)
    end

    update_from_pds
  end

  def update_from_pds
    return unless Settings.pds.perform_jobs

    patients.find_each do |patient|
      if patient.nhs_number.nil?
        PatientNHSNumberLookupJob.perform_later(patient)
      else
        PatientUpdateFromPDSJob.perform_later(patient)
      end
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

  def headers_are_valid
    return unless data

    missing_headers = required_headers - data.headers
    errors.add(:csv, :missing_headers, missing_headers:) if missing_headers.any?
  end

  def rows_are_valid
    return unless rows

    rows.each.with_index do |row, index|
      if row.invalid?
        errors.add("row_#{index + 1}".to_sym, row.errors.full_messages)
      end
    end
  end

  def ensure_recorded_with_count_statistics
    if recorded? && count_columns.any? { |column| send(column).nil? }
      raise "Count statistics must be set for a recorded import."
    elsif !recorded? && count_columns.any? { |column| !send(column).nil? }
      raise "Count statistics must not be set for a non-recorded import."
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
