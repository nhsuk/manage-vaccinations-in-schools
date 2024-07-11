# frozen_string_literal: true

require "csv"

# == Schema Information
#
# Table name: immunisation_imports
#
#  id         :bigint           not null, primary key
#  csv        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ImmunisationImport < ApplicationRecord
  attr_accessor :csv_is_malformed, :data

  belongs_to :user

  EXPECTED_HEADERS = %w[DATE_OF_VACCINATION].freeze

  validates :csv, presence: true
  validate :csv_is_valid
  validate :csv_has_records
  validate :headers_are_valid

  def csv=(value)
    super(value.respond_to?(:read) ? value.read : value)
  end

  def load_data!
    return if invalid?

    self.data ||= CSV.parse(csv, headers: true, skip_blanks: true)
  rescue CSV::MalformedCSVError
    self.csv_is_malformed = true
  ensure
    csv.close if csv.respond_to?(:close)
  end

  def process!(patient_session:)
    load_data! if data.nil?
    return if invalid?

    data.each do |row|
      record = Row.new(row).to_vaccination_record
      record.user = user
      record.patient_session = patient_session
      record.save!
    end
  end

  private

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

    missing_headers = EXPECTED_HEADERS - data.headers
    errors.add(:csv, :missing_headers, missing_headers:) if missing_headers.any?
  end

  class Row
    def initialize(row)
      @row = row
    end

    def to_vaccination_record
      VaccinationRecord.new(
        administered:,
        delivery_site:,
        delivery_method:,
        recorded_at:
      )
    end

    DELIVERY_SITES = {
      "left thigh" => :left_thigh,
      "right thigh" => :right_thigh,
      "left upper arm" => :left_arm_upper_position,
      "right upper arm" => :right_arm_upper_position,
      "left buttock" => :left_buttock,
      "right buttock" => :right_buttock,
      "nasal" => :nose
    }.freeze

    def delivery_site
      DELIVERY_SITES[@row["ANATOMICAL_SITE"]&.downcase]
    end

    def delivery_method
      if delivery_site == :nose
        :nasal_spray
      else
        :intramuscular
      end
    end

    def administered
      vaccinated = @row["VACCINATED"]&.downcase

      if vaccinated == "yes"
        true
      elsif vaccinated == "no"
        false
      end
    end

    def recorded_at
      Time.zone.now
    end
  end
end
