# frozen_string_literal: true

require "csv"

# == Schema Information
#
# Table name: immunisation_imports
#
#  id          :bigint           not null, primary key
#  csv         :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_campaign_id  (campaign_id)
#  index_immunisation_imports_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (user_id => users.id)
#
class ImmunisationImport < ApplicationRecord
  attr_accessor :csv_is_malformed, :data, :rows

  belongs_to :user
  belongs_to :campaign
  with_options dependent: :restrict_with_exception,
               foreign_key: :imported_from_id do
    has_many :vaccination_records
    has_many :locations
    has_many :sessions
    has_many :patients
  end

  EXPECTED_HEADERS = %w[
    ANATOMICAL_SITE
    DATE_OF_VACCINATION
    ORGANISATION_CODE
    SCHOOL_NAME
    SCHOOL_URN
    VACCINATED
  ].freeze

  validates :csv, presence: true
  validate :csv_is_valid
  validate :csv_has_records
  validate :headers_are_valid
  validate :rows_are_valid

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

  def parse_rows!
    load_data! if data.nil?
    return if invalid?

    self.rows =
      data.map do |row_data|
        Row.new(data: row_data, campaign:, team: user.team)
      end
  end

  def process!
    parse_rows! if rows.nil?
    return if invalid?

    ActiveRecord::Base.transaction do
      rows
        .map(&:to_location)
        .reject(&:persisted?)
        .uniq(&:urn)
        .reject(&:invalid?)
        .each do |location|
          location.imported_from = self
          location.save!
        end

      rows
        .map(&:to_patient)
        .reject(&:persisted?)
        .uniq(&:nhs_number)
        .reject(&:invalid?)
        .each do |patient|
          patient.imported_from = self
          patient.save!
        end

      rows
        .map(&:to_session)
        .reject(&:persisted?)
        .uniq { [_1.date, _1.location_id] }
        .reject(&:invalid?)
        .each do |session|
          session.imported_from = self
          session.save!
        end

      rows
        .map { [_1.to_patient_session, _1.to_vaccination_record] }
        .each do |patient_session, record|
          patient_session.created_by = user
          patient_session.save!

          record.user = user
          record.patient_session = patient_session
          record.imported_from = self
          record.save!
        end
    end
  end

  class Row
    include ActiveModel::Model

    validates :administered, inclusion: [true, false]
    validates :delivery_method, presence: true, if: :administered
    validates :delivery_site, presence: true, if: :administered
    validates :organisation_code,
              presence: true,
              length: {
                maximum: 5
              },
              comparison: {
                equal_to: :valid_ods_code
              }
    validates :recorded_at, presence: true

    validates :school_name, presence: true
    validates :school_urn, presence: true

    validates :patient_first_name, presence: true
    validates :patient_last_name, presence: true
    validates :patient_nhs_number, presence: true
    validates :patient_date_of_birth,
              presence: true,
              format: {
                with: /\A\d{8}\z/
              },
              comparison: {
                less_than_or_equal_to: -> { Date.current.strftime("%Y%m%d") }
              }
    validates :patient_gender_code,
              presence: true,
              inclusion: {
                in: Patient.gender_codes.values
              }
    validates :patient_postcode, presence: true, postcode: true

    validates :session_date,
              presence: true,
              format: {
                with: /\A\d{8}\z/
              },
              comparison: {
                less_than_or_equal_to: -> { Date.current.strftime("%Y%m%d") }
              }

    def initialize(data:, campaign:, team:)
      @data = data
      @campaign = campaign
      @team = team
    end

    def to_location
      return unless valid?

      location = Location.find_or_initialize_by(urn: school_urn)
      location.name ||= school_name
      location
    end

    def to_session
      return unless valid?

      @campaign.sessions.find_or_initialize_by(
        date: session_date,
        location: Location.find_by(urn: school_urn)
      )
    end

    def to_patient
      return unless valid?

      patient = Patient.find_or_initialize_by(nhs_number: patient_nhs_number)
      patient.first_name ||= patient_first_name
      patient.last_name ||= patient_last_name
      patient.date_of_birth ||= patient_date_of_birth
      patient.address_postcode ||= patient_postcode
      patient.gender_code ||= patient_gender_code
      patient.location ||= to_location
      patient
    end

    def to_patient_session
      return unless valid?

      PatientSession.find_or_initialize_by(
        patient: to_patient,
        session: to_session
      )
    end

    def to_vaccination_record
      return unless valid?

      VaccinationRecord.new(
        administered:,
        delivery_site:,
        delivery_method:,
        recorded_at:
      )
    end

    def administered
      vaccinated = @data["VACCINATED"]&.downcase

      if vaccinated == "yes"
        true
      elsif vaccinated == "no"
        false
      end
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
      DELIVERY_SITES[@data["ANATOMICAL_SITE"]&.downcase]
    end

    def delivery_method
      return unless delivery_site

      if delivery_site == :nose
        :nasal_spray
      else
        :intramuscular
      end
    end

    def recorded_at
      Time.zone.now
    end

    def organisation_code
      @data["ORGANISATION_CODE"]&.strip
    end

    def patient_first_name
      @data["PERSON_FORENAME"]&.strip
    end

    def patient_last_name
      @data["PERSON_SURNAME"]&.strip
    end

    def patient_date_of_birth
      @data["PERSON_DOB"]&.strip
    end

    PATIENT_GENDER_CODES = {
      "not known" => 0,
      "male" => 1,
      "female" => 2,
      "not specified" => 9
    }.freeze

    def patient_gender_code
      PATIENT_GENDER_CODES[@data["PERSON_GENDER_CODE"]&.strip&.downcase]
    end

    def patient_postcode
      if (postcode = @data["PERSON_POSTCODE"]).present?
        UKPostcode.parse(postcode).to_s
      end
    end

    def patient_nhs_number
      @data["NHS_NUMBER"]&.gsub(/\s/, "")
    end

    def school_name
      @data["SCHOOL_NAME"]&.strip
    end

    def school_urn
      @data["SCHOOL_URN"]&.strip
    end

    def session_date
      @data["DATE_OF_VACCINATION"]&.strip
    end

    private

    def valid_ods_code
      @team.ods_code
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

  def rows_are_valid
    return unless rows

    rows.each.with_index do |row, index|
      next if row.valid?

      # Row 0 is the header row, but humans would call it Row 1. That's also
      # what it would be shown as in Excel. The first row of data is Row 2.
      errors.add("row_#{index + 2}".to_sym, row.errors.full_messages)
    end
  end
end
