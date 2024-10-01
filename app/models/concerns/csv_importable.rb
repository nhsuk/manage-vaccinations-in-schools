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

    scope :csv_not_removed, -> { where(csv_removed_at: nil) }

    enum :status,
         %i[pending_import rows_are_invalid processed],
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

    before_save :ensure_processed_with_count_statistics
  end

  def csv=(file)
    self.csv_data = file&.read
    self.csv_filename = file&.original_filename
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

    self.data ||= CSV.parse(csv_data, headers: true, skip_blanks: true)
  rescue CSV::MalformedCSVError
    self.csv_is_malformed = true
  end

  def parse_rows!
    load_data! if data.nil?
    return if invalid?

    self.rows = data.map { |row_data| parse_row(row_data) }

    if invalid?
      self.serialized_errors = errors.to_hash
      self.status = :rows_are_invalid
      save!(validate: false)
    end
  end

  def process!
    return if processed?

    parse_rows! if rows.nil?
    return if invalid?

    counts = count_columns.index_with(0)

    ActiveRecord::Base.transaction do
      save!

      rows.each do |row|
        count_column_to_increment = process_row(row)
        counts[count_column_to_increment] += 1
      end

      update!(processed_at: Time.zone.now, status: :processed, **counts)
    end
  end

  def record!
    return if recorded?

    process! unless processed?
    return if invalid?

    ActiveRecord::Base.transaction do
      record_rows
      update!(recorded_at: Time.zone.now)
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

  def ensure_processed_with_count_statistics
    if processed? && count_columns.any? { |column| send(column).nil? }
      raise "Count statistics must be set for a processed import."
    elsif !processed? && count_columns.any? { |column| !send(column).nil? }
      raise "Count statistics must not be set for a non-processed import."
    end
  end
end
