# frozen_string_literal: true

class ImmunisationImportRow
  include ActiveModel::Model

  validates :administered, inclusion: [true, false]
  validates :batch_expiry_date, presence: true, if: :administered
  validates :batch_expiry_date,
            comparison: {
              greater_than: -> { Date.new(Date.current.year - 15, 1, 1) },
              less_than: -> { Date.new(Date.current.year + 15, 1, 1) }
            },
            if: -> { administered && batch_expiry_date.present? }
  validates :batch_number, presence: true, if: :administered
  validates :delivery_site, presence: true, if: :administered
  validates :dose_sequence,
            comparison: {
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: :maximum_dose_sequence
            },
            if: -> { administered && vaccine.present? }
  validates :organisation_code, comparison: { equal_to: :ods_code }
  validates :vaccine_given,
            inclusion: {
              in: :valid_given_vaccines
            },
            if: :administered

  SCHOOL_URN_HOME_EDUCATED = "999999"
  SCHOOL_URN_UNKNOWN = "888888"

  validates :school_name,
            presence: true,
            if: -> { school_urn == SCHOOL_URN_UNKNOWN }
  validate :school_urn_inclusion

  validates :existing_patients, length: { maximum: 1 }
  validates :patient_nhs_number, length: { is: 10 }, allow_blank: true
  validates :patient_first_name, presence: true
  validates :patient_last_name, presence: true
  validates :patient_date_of_birth, presence: true
  validates :patient_gender_code, inclusion: { in: Patient.gender_codes.keys }
  validates :patient_postcode, postcode: true
  validate :date_of_birth_in_a_valid_year_group

  validates :session_date,
            comparison: {
              greater_than_or_equal_to: Date.new(2021, 9, 1),
              less_than_or_equal_to: -> { Date.current }
            }

  CARE_SETTING_SCHOOL = 1
  CARE_SETTING_COMMUNITY = 2

  validates :care_setting,
            inclusion: [CARE_SETTING_SCHOOL, CARE_SETTING_COMMUNITY],
            allow_nil: true
  validates :care_setting, presence: true, if: :requires_care_setting?

  validates :performed_by_given_name,
            :performed_by_family_name,
            presence: true,
            if: :requires_performed_by?

  def initialize(data:, organisation:, programme:)
    @data = data
    @organisation = organisation
    @programme = programme
  end

  def to_vaccination_record
    return unless valid?

    return unless administered

    vaccination_record =
      VaccinationRecord.create_with(
        recorded_at: Time.zone.now
      ).find_or_initialize_by(
        administered_at:,
        dose_sequence:,
        location_name:,
        patient_session:,
        performed_by_family_name:,
        performed_by_given_name:,
        programme: @programme,
        vaccine:
      )

    if vaccination_record.persisted?
      vaccination_record.stage_changes(
        batch_id: batch.id,
        delivery_method:,
        delivery_site:
      )
    else
      # Postgres UUID generation is skipped in bulk import
      vaccination_record.uuid = SecureRandom.uuid

      vaccination_record.batch = batch
      vaccination_record.delivery_method = delivery_method
      vaccination_record.delivery_site = delivery_site
    end

    vaccination_record
  end

  def patient
    return unless valid?

    @patient ||=
      if (existing_patient = existing_patients.first)
        existing_patient.stage_changes(patient_attributes)
        existing_patient
      else
        Patient.create!(patient_attributes)
      end
  end

  def session
    return unless valid?

    @session ||=
      Session
        .create_with(programmes: [@programme])
        .find_or_create_by!(
          organisation:,
          location:,
          academic_year: session_date.academic_year
        )
        .tap do |session|
          unless session.programmes.include?(@programme)
            session.programmes << @programme
          end

          session.session_dates.find_or_create_by!(value: session_date)
        end
  end

  def patient_session
    return unless valid?

    @patient_session ||= PatientSession.find_or_create_by!(patient:, session:)
  end

  def location_name
    return unless location&.generic_clinic?

    if school_urn == SCHOOL_URN_UNKNOWN &&
         (care_setting.nil? || care_setting == CARE_SETTING_SCHOOL)
      school_name
    else
      "Unknown"
    end
  end

  def administered
    if (vaccinated = @data["VACCINATED"]&.downcase).present?
      if "yes".start_with?(vaccinated)
        true
      elsif "no".start_with?(vaccinated)
        false
      end
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

  DELIVERY_SITES = {
    "left thigh" => "left_thigh",
    "right thigh" => "right_thigh",
    "left upper arm" => "left_arm_upper_position",
    "right upper arm" => "right_arm_upper_position",
    "left buttock" => "left_buttock",
    "right buttock" => "right_buttock",
    "nasal" => "nose"
  }.freeze

  def delivery_site
    DELIVERY_SITES[@data["ANATOMICAL_SITE"]&.strip&.downcase]
  end

  def delivery_method
    return unless delivery_site

    if delivery_site == "nose"
      "nasal_spray"
    else
      "intramuscular"
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

  def organisation_code
    @data["ORGANISATION_CODE"]&.strip&.upcase
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

  def patient_gender_code
    gender_code = @data["PERSON_GENDER_CODE"] || @data["PERSON_GENDER"]
    gender_code&.strip&.downcase&.gsub(" ", "_")
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

  def care_setting
    Integer(@data["CARE_SETTING"])
  rescue ArgumentError, TypeError
    nil
  end

  def performed_by_given_name
    @data["PERFORMING_PROFESSIONAL_FORENAME"]&.strip&.presence
  end

  def performed_by_family_name
    @data["PERFORMING_PROFESSIONAL_SURNAME"]&.strip&.presence
  end

  private

  attr_reader :organisation

  delegate :ods_code, to: :organisation

  def administered_at
    administered ? (session_date.in_time_zone + 12.hours) : nil
  end

  def location
    return unless valid?

    @location ||=
      if school && (care_setting.nil? || care_setting == CARE_SETTING_SCHOOL)
        school
      else
        organisation.generic_clinic
      end
  end

  def school
    return unless valid?

    @school ||=
      if school_urn != SCHOOL_URN_HOME_EDUCATED &&
           school_urn != SCHOOL_URN_UNKNOWN
        Location.find_by!(urn: school_urn)
      end
  end

  def vaccine
    return unless administered

    @vaccine ||= @programme.vaccines.find_by(nivs_name: vaccine_given)
  end

  def batch
    return unless valid? && administered

    @batch ||=
      Batch.create_with(archived_at: Time.current).find_or_create_by!(
        expiry: batch_expiry_date,
        name: batch_number,
        organisation:,
        vaccine:
      )
  end

  def valid_given_vaccines
    @programme.vaccines.pluck(:nivs_name)
  end

  def maximum_dose_sequence
    vaccine.maximum_dose_sequence
  end

  def requires_care_setting?
    @programme.hpv?
  end

  def requires_performed_by?
    administered && @programme.flu?
  end

  def parse_date(key)
    Date.strptime(@data[key]&.strip, "%Y%m%d")
  rescue ArgumentError, TypeError
    nil
  end

  def date_of_birth_in_a_valid_year_group
    return if patient_date_of_birth.nil?

    unless @programme.year_groups.include?(patient_date_of_birth.year_group)
      errors.add(:patient_date_of_birth, :inclusion)
    end
  end

  def existing_patients
    if patient_first_name.blank? || patient_last_name.blank? ||
         patient_date_of_birth.nil? || patient_postcode.blank?
      return
    end

    Patient.match_existing(
      nhs_number: patient_nhs_number,
      given_name: patient_first_name,
      family_name: patient_last_name,
      date_of_birth: patient_date_of_birth,
      address_postcode: patient_postcode
    )
  end

  def patient_attributes
    {
      address_postcode: patient_postcode,
      date_of_birth: patient_date_of_birth,
      family_name: patient_last_name,
      given_name: patient_first_name,
      gender_code: patient_gender_code,
      nhs_number: patient_nhs_number
    }.compact
  end

  def school_urn_inclusion
    unless Location.school.exists?(urn: school_urn) ||
             school_urn.in?([SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN])
      errors.add(:school_urn, :inclusion)
    end
  end
end
