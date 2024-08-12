# frozen_string_literal: true

class ImmunisationImportRow
  include ActiveModel::Model

  validates :administered, inclusion: [true, false]
  validates :batch_expiry_date, presence: true, if: :administered
  validates :batch_number, presence: true, if: :administered
  validates :delivery_method, presence: true, if: :administered
  validates :delivery_site, presence: true, if: :administered
  validates :dose_sequence,
            presence: true,
            comparison: {
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: :maximum_dose_sequence
            },
            if: -> { administered && vaccine.present? }
  validates :organisation_code,
            presence: true,
            length: {
              maximum: 5
            },
            comparison: {
              equal_to: :valid_ods_code
            }
  validates :recorded_at, presence: true
  validates :vaccine_given,
            presence: true,
            inclusion: {
              in: :valid_given_vaccines
            },
            if: :administered

  validates :school_name, presence: true
  validates :school_urn, presence: true

  validates :patient_first_name, presence: true
  validates :patient_last_name, presence: true
  validates :patient_date_of_birth,
            presence: true,
            comparison: {
              less_than_or_equal_to: -> { Date.current }
            }
  validates :patient_gender_code,
            presence: true,
            inclusion: {
              in: Patient.gender_codes.values
            }
  validates :patient_postcode, presence: true, postcode: true
  validate :zero_or_one_existing_patient

  validates :session_date,
            presence: true,
            comparison: {
              less_than_or_equal_to: -> { Date.current }
            }
  validates :reason,
            presence: true,
            inclusion: {
              in: VaccinationRecord.reasons.keys.map(&:to_sym)
            },
            unless: :administered

  def initialize(data:, campaign:, user:, imported_from:)
    @data = data
    @campaign = campaign
    @user = user
    @imported_from = imported_from
  end

  def to_vaccination_record
    return unless valid?

    return unless administered

    VaccinationRecord.create_with(
      imported_from: @imported_from,
      recorded_at:,
      user: @user
    ).find_or_create_by!(
      administered:,
      delivery_method:,
      delivery_site:,
      dose_sequence:,
      patient_session:,
      reason:,
      batch:,
      vaccine:
    )
  end

  def patient
    return unless valid?

    @patient ||=
      find_existing_patients.first ||
        Patient.create!(
          address_postcode: patient_postcode,
          date_of_birth: patient_date_of_birth,
          first_name: patient_first_name,
          gender_code: patient_gender_code,
          imported_from:,
          last_name: patient_last_name,
          location:,
          nhs_number: patient_nhs_number
        )
  end

  def administered
    vaccinated = @data["VACCINATED"]&.downcase

    if vaccinated == "yes"
      true
    elsif vaccinated == "no"
      false
    elsif @data["VACCINE_GIVEN"].present?
      true
    end
  end

  def batch_expiry_date
    parse_date("BATCH_EXPIRY_DATE")
  end

  def batch_number
    @data["BATCH_NUMBER"]&.strip
  end

  def reason
    {
      "Did Not Attend" => :absent_from_session,
      "Vaccination Contraindicated" => :contraindications,
      "Unwell" => :not_well
    }[
      @data["REASON_NOT_VACCINATED"]&.strip
    ]
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

  def dose_sequence
    return 1 unless administered

    if vaccine.maximum_dose_sequence == 1 && !@data.key?("DOSE_SEQUENCE")
      return 1
    end

    begin
      Integer(@data["DOSE_SEQUENCE"])
    rescue ArgumentError, TypeError
      nil
    end
  end

  def recorded_at
    Time.zone.now
  end

  def organisation_code
    @data["ORGANISATION_CODE"]&.strip
  end

  def vaccine_given
    @data["VACCINE_GIVEN"]&.strip
  end

  def patient_first_name
    @data["PERSON_FORENAME"]&.strip
  end

  def patient_last_name
    @data["PERSON_SURNAME"]&.strip
  end

  def patient_date_of_birth
    parse_date("PERSON_DOB")
  end

  PATIENT_GENDER_CODES = {
    "not known" => 0,
    "male" => 1,
    "female" => 2,
    "not specified" => 9
  }.freeze

  def patient_gender_code
    gender_code = @data["PERSON_GENDER_CODE"] || @data["PERSON_GENDER"]
    PATIENT_GENDER_CODES[gender_code&.strip&.downcase]
  end

  def patient_postcode
    if (postcode = @data["PERSON_POSTCODE"]).present?
      UKPostcode.parse(postcode).to_s
    end
  end

  def patient_nhs_number
    @data["NHS_NUMBER"]&.gsub(/\s/, "")&.presence
  end

  def school_name
    @data["SCHOOL_NAME"]&.strip
  end

  def school_urn
    @data["SCHOOL_URN"]&.strip
  end

  def session_date
    parse_date("DATE_OF_VACCINATION")
  end

  private

  attr_reader :imported_from

  def location
    return unless valid?

    @location ||=
      Location.create_with(
        name: school_name,
        imported_from:
      ).find_or_create_by!(urn: school_urn)
  end

  def session
    return unless valid?

    @session ||=
      @campaign
        .sessions
        .create_with(imported_from:)
        .find_or_create_by!(
          date: session_date,
          location:,
          time_of_day: :all_day
        )
  end

  def patient_session
    return unless valid?

    @patient_session ||=
      PatientSession.create_with(created_by: @user).find_or_create_by!(
        patient:,
        session:
      )
  end

  def vaccine
    return unless administered

    @vaccine ||= @campaign.vaccines.find_by(nivs_name: vaccine_given)
  end

  def batch
    return unless valid? && administered

    @batch ||=
      Batch.find_or_create_by!(
        vaccine:,
        expiry: batch_expiry_date,
        name: batch_number
      )
  end

  def valid_ods_code
    @user.team.ods_code
  end

  def valid_given_vaccines
    @campaign.vaccines.pluck(:nivs_name)
  end

  def maximum_dose_sequence
    vaccine.maximum_dose_sequence
  end

  def parse_date(key)
    Date.strptime(@data[key]&.strip, "%Y%m%d")
  rescue ArgumentError, TypeError
    nil
  end

  def find_existing_patients
    @find_existing_patients ||=
      begin
        if patient_nhs_number.present? &&
             (
               patient = Patient.find_by(nhs_number: patient_nhs_number)
             ).present?
          return [patient]
        end

        first_name = patient_first_name
        last_name = patient_last_name
        date_of_birth = patient_date_of_birth
        address_postcode = patient_postcode

        Patient
          .where(first_name:, last_name:, date_of_birth:)
          .or(Patient.where(first_name:, last_name:, address_postcode:))
          .or(Patient.where(first_name:, date_of_birth:, address_postcode:))
          .or(Patient.where(last_name:, date_of_birth:, address_postcode:))
          .to_a
      end
  end

  def zero_or_one_existing_patient
    if find_existing_patients.count >= 2
      errors.add(:patient_first_name, :multiple_duplicate_match)
    end
  end
end
