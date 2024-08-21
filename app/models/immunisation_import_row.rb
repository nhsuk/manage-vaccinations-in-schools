# frozen_string_literal: true

class ImmunisationImportRow
  include ActiveModel::Model

  validates :administered, inclusion: [true, false]
  validates :batch_expiry_date, presence: true, if: :administered
  validates :batch_number, presence: true, if: :administered
  validates :delivery_site, presence: true, if: :administered
  validates :dose_sequence,
            comparison: {
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: :maximum_dose_sequence
            },
            if: -> { administered && vaccine.present? }
  validates :organisation_code, comparison: { equal_to: :valid_ods_code }
  validates :recorded_at, presence: true
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
  validates :school_urn,
            inclusion: {
              in: -> do
                Location.school.pluck(:urn) +
                  [SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN]
              end
            }

  validates :patient_nhs_number, length: { is: 10 }, allow_blank: true
  validates :patient_first_name, presence: true
  validates :patient_last_name, presence: true
  validates :patient_date_of_birth,
            comparison: {
              less_than_or_equal_to: -> { Date.current }
            }
  validates :patient_gender_code, inclusion: { in: Patient.gender_codes.values }
  validates :patient_postcode, postcode: true
  validate :zero_or_one_existing_patient

  validates :session_date,
            comparison: {
              greater_than_or_equal_to: :campaign_start_date,
              less_than_or_equal_to: :campaign_end_date_or_today
            }
  validates :reason, presence: true, if: -> { administered == false }

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
      notes:,
      recorded_at:
    ).find_or_create_by!(
      administered_at:,
      batch:,
      delivery_method:,
      delivery_site:,
      dose_sequence:,
      patient_session:,
      performed_by_family_name:,
      performed_by_given_name:,
      reason:,
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
          home_educated:,
          imported_from:,
          last_name: patient_last_name,
          nhs_number: patient_nhs_number,
          school:
        )
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

  def notes
    "Vaccinated at #{school_name}" if school_name.present? && location.nil?
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

  REASONS = {
    "did not attend" => :absent_from_session,
    "vaccination contraindicated" => :contraindications,
    "unwell" => :not_well
  }.freeze

  def reason
    REASONS[@data["REASON_NOT_VACCINATED"]&.strip&.downcase]
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
    DELIVERY_SITES[@data["ANATOMICAL_SITE"]&.strip&.downcase]
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

  def home_educated
    school_urn == SCHOOL_URN_HOME_EDUCATED
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

  attr_reader :imported_from

  def administered_at
    administered ? (session_date.in_time_zone + 12.hours) : nil
  end

  def location
    return unless valid?

    @location ||=
      if school.present? &&
           (care_setting.nil? || care_setting == CARE_SETTING_SCHOOL)
        school
      elsif home_educated || care_setting == CARE_SETTING_COMMUNITY
        generic_clinic
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

  def generic_clinic
    return unless valid?

    @generic_clinic ||=
      Location.create_with(
        name: "Generic #{@user.team.name} clinic"
      ).find_or_create_by!(type: :generic_clinic, ods_code: @user.team.ods_code)
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

  def campaign_start_date
    @campaign.start_date
  end

  def campaign_end_date_or_today
    [@campaign.end_date, Date.current].min
  end

  def requires_care_setting?
    vaccine&.hpv?
  end

  def requires_performed_by?
    vaccine&.flu?
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
      errors.add(:patient, :multiple_duplicate_match)
    end
  end
end
