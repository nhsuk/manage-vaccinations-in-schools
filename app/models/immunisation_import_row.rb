# frozen_string_literal: true

class ImmunisationImportRow
  include ActiveModel::Model

  validates :administered, inclusion: [true, false]

  with_options if: :administered do
    validates :batch_expiry_date, presence: true
    validates :batch_number, presence: true
    validates :delivery_site, presence: true
    validates :reason, absence: true
  end

  with_options unless: :administered do
    validates :batch_expiry_date, absence: true
    validates :batch_number, absence: true
    validates :delivery_site, absence: true
    validates :reason, presence: true
  end

  validates :vaccine_given, inclusion: { in: :valid_given_vaccines }

  validates :batch_expiry_date,
            comparison: {
              greater_than: -> { Date.new(Date.current.year - 15, 1, 1) },
              less_than: -> { Date.new(Date.current.year + 15, 1, 1) }
            },
            if: :batch_expiry_date
  validate :delivery_site_appropriate_for_vaccine,
           if: -> { administered && delivery_site.present? && vaccine.present? }
  validates :dose_sequence,
            comparison: {
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: :maximum_dose_sequence
            },
            if: :vaccine

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
  validates :patient_date_of_birth,
            comparison: {
              less_than: -> { Date.current }
            }
  validates :patient_gender_code, inclusion: { in: Patient.gender_codes.keys }
  validates :patient_postcode,
            postcode: {
              allow_nil: true
            },
            presence: {
              if: -> do
                @data["PERSON_POSTCODE"]&.strip.present? ||
                  patient_nhs_number.blank?
              end
            }

  validates :performed_ods_code,
            presence: {
              unless: :outcome_in_this_academic_year?
            },
            comparison: {
              equal_to: :organisation_ods_code,
              if: :outcome_in_this_academic_year?
            }

  validates :date_of_vaccination,
            comparison: {
              greater_than_or_equal_to: Date.new(2021, 9, 1),
              less_than_or_equal_to: -> { Date.current }
            }
  validates :time_of_vaccination,
            presence: {
              if: -> { @data["TIME_OF_VACCINATION"]&.strip.present? }
            },
            comparison: {
              less_than_or_equal_to: -> { Time.current },
              if: -> do
                @data["TIME_OF_VACCINATION"]&.strip.present? &&
                  date_of_vaccination == Date.current
              end
            }
  validate :session_date_exists
  validate :uuid_exists

  CARE_SETTING_SCHOOL = 1
  CARE_SETTING_COMMUNITY = 2

  validates :care_setting,
            inclusion: [CARE_SETTING_SCHOOL, CARE_SETTING_COMMUNITY],
            allow_nil: true
  validates :care_setting, presence: true, if: :requires_care_setting?
  validates :clinic_name,
            inclusion: {
              if: -> do
                outcome_in_this_academic_year? &&
                  care_setting == CARE_SETTING_COMMUNITY
              end,
              in: -> { _1.organisation.community_clinics.map(&:name) }
            }

  validate :performed_by_details_present_where_required

  attr_reader :organisation

  def initialize(data:, organisation:)
    @data = data
    @organisation = organisation
  end

  def to_vaccination_record
    return unless valid?

    outcome = (administered ? "administered" : reason)

    attributes = {
      dose_sequence:,
      location_name:,
      outcome:,
      patient:,
      performed_at:,
      performed_by_family_name:,
      performed_by_given_name:,
      performed_by_user:,
      performed_ods_code:,
      programme:,
      session:
    }

    vaccination_record =
      if uuid.present?
        VaccinationRecord
          .joins(:organisation)
          .find_by!(organisations: { id: organisation.id }, uuid:)
          .tap { _1.assign_attributes(attributes) }
      else
        VaccinationRecord.find_or_initialize_by(attributes)
      end

    if vaccination_record.persisted?
      vaccination_record.stage_changes(
        batch_id: batch&.id,
        delivery_method:,
        delivery_site:,
        notes:
      )
    else
      # Postgres UUID generation is skipped in bulk import
      vaccination_record.uuid = SecureRandom.uuid

      vaccination_record.batch = batch
      vaccination_record.delivery_method = delivery_method
      vaccination_record.delivery_site = delivery_site
      vaccination_record.notes = notes
    end

    vaccination_record
  end

  def patient
    return unless valid?

    @patient ||=
      existing_patients.first || Patient.create!(new_patient_attributes)
  end

  def session
    return if date_of_vaccination.nil? || location.nil?

    @session ||=
      Session.has_date(date_of_vaccination).find_by(
        organisation:,
        location:,
        academic_year:
      )
  end

  def location_name
    return unless session.nil? || location&.generic_clinic?

    if school_urn == SCHOOL_URN_UNKNOWN &&
         (
           (care_setting.nil? && clinic_name.blank?) ||
             care_setting == CARE_SETTING_SCHOOL
         )
      school_name
    else
      clinic_name.presence || "Unknown"
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

  REASONS = {
    "refused" => :refused,
    "unwell" => :not_well,
    "vaccination contraindicated" => :contraindications,
    "already had elsewhere" => :already_had,
    "did not attend" => :absent_from_session,
    "absent from school" => :absent_from_school
  }.freeze

  def reason
    REASONS[@data["REASON_NOT_VACCINATED"]&.strip&.downcase]
  end

  def notes
    @data["NOTES"]&.strip&.presence
  end

  DELIVERY_SITES = {
    "left thigh" => "left_thigh",
    "right thigh" => "right_thigh",
    "left upper arm" => "left_arm_upper_position",
    "left arm (upper position)" => "left_arm_upper_position",
    "left arm (lower position)" => "left_arm_lower_position",
    "right upper arm" => "right_arm_upper_position",
    "right arm (upper position)" => "right_arm_upper_position",
    "right arm (lower position)" => "right_arm_lower_position",
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

  def patient_birth_academic_year
    patient_date_of_birth&.academic_year
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

  def performed_ods_code
    @data["ORGANISATION_CODE"]&.strip&.upcase
  end

  def school_name
    @data["SCHOOL_NAME"]&.strip
  end

  def clinic_name
    @data["CLINIC_NAME"]&.strip
  end

  def school_urn
    @data["SCHOOL_URN"]&.strip
  end

  def date_of_vaccination
    @date_of_vaccination ||= parse_date("DATE_OF_VACCINATION")
  end

  def time_of_vaccination
    @time_of_vaccination ||= parse_time("TIME_OF_VACCINATION")
  end

  delegate :academic_year, to: :date_of_vaccination

  def care_setting
    Integer(@data["CARE_SETTING"])
  rescue ArgumentError, TypeError
    nil
  end

  def performed_by_user
    @performed_by_user ||=
      if (email = @data["PERFORMING_PROFESSIONAL_EMAIL"]&.strip)
        User.find_by(email:)
      end
  end

  def performed_by_given_name
    @performed_by_given_name ||=
      if performed_by_user.nil?
        @data["PERFORMING_PROFESSIONAL_FORENAME"]&.strip&.presence
      end
  end

  def performed_by_family_name
    @performed_by_family_name ||=
      if performed_by_user.nil?
        @data["PERFORMING_PROFESSIONAL_SURNAME"]&.strip&.presence
      end
  end

  def uuid
    @data["UUID"]&.strip&.presence
  end

  private

  def performed_at
    return nil if date_of_vaccination.nil?

    Time.zone.local(
      date_of_vaccination.year,
      date_of_vaccination.month,
      date_of_vaccination.day,
      time_of_vaccination&.hour || 12,
      time_of_vaccination&.min || 0,
      time_of_vaccination&.sec || 0
    )
  end

  def location
    @location ||=
      if school &&
           (
             (care_setting.nil? && clinic_name.blank?) ||
               care_setting == CARE_SETTING_SCHOOL
           )
        school
      else
        organisation.generic_clinic
      end
  end

  def school
    @school ||=
      if school_urn != SCHOOL_URN_HOME_EDUCATED &&
           school_urn != SCHOOL_URN_UNKNOWN
        Location.find_by(urn: school_urn)
      end
  end

  def vaccine
    @vaccine ||=
      organisation
        .vaccines
        .includes(:programme)
        .find_by(nivs_name: vaccine_given)
  end

  delegate :programme, to: :vaccine, allow_nil: true

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

  def organisation_ods_code
    organisation.ods_code
  end

  def valid_given_vaccines
    organisation.vaccines.pluck(:nivs_name)
  end

  def maximum_dose_sequence
    vaccine.maximum_dose_sequence
  end

  # TODO: we want tougher validation from the point of integration of Mavis
  # but permit looser validation in historical data
  # in the future, this check should change to apply from a specific point in time,
  # not the current academic year
  def outcome_in_this_academic_year?
    date_of_vaccination.present? && academic_year == Date.current.academic_year
  end

  def requires_care_setting?
    programme&.hpv?
  end

  def performed_by_details_present_where_required
    if outcome_in_this_academic_year?
      errors.add(:performed_by_user, :blank) if performed_by_user.nil?
    else # previous academic years from here on
      email_field_populated =
        @data["PERFORMING_PROFESSIONAL_EMAIL"]&.strip.present?

      if email_field_populated
        errors.add(:performed_by_user, :blank) if performed_by_user.nil?
      elsif programme&.flu? # no validation required for HPV
        if performed_by_given_name.blank?
          errors.add(:performed_by_given_name, :blank)
        end
        if performed_by_family_name.blank?
          errors.add(:performed_by_family_name, :blank)
        end
      end
    end
  end

  DATE_FORMATS = %w[%Y%m%d %Y-%m-%d %d/%m/%Y].freeze

  def parse_date(key)
    value = @data[key]&.strip
    return nil if value.nil?

    parsed_dates =
      DATE_FORMATS.lazy.filter_map do |format|
        Date.strptime(value, format)
      rescue ArgumentError, TypeError
        nil
      end

    parsed_dates.first
  end

  TIME_FORMATS = %w[%H:%M:%S %H:%M %H%M%S %H%M %H].freeze

  def parse_time(key)
    value = @data[key]&.strip
    return nil if value.nil?

    parsed_times =
      TIME_FORMATS.lazy.filter_map do |format|
        Time.strptime(value, format)
      rescue ArgumentError, TypeError
        nil
      end

    parsed_times.first
  end

  def delivery_site_appropriate_for_vaccine
    return if vaccine.nil? || delivery_site.nil?
    return unless outcome_in_this_academic_year?

    unless vaccine.available_delivery_sites.include?(delivery_site)
      errors.add(:delivery_site, :inclusion)
    end
  end

  def session_date_exists
    return if date_of_vaccination.nil?
    return unless outcome_in_this_academic_year?

    errors.add(:date_of_vaccination, :inclusion) if session.nil?
  end

  def uuid_exists
    if uuid.present? &&
         !VaccinationRecord.joins(:organisation).exists?(
           organisations: {
             id: organisation.id
           },
           uuid:
         )
      errors.add(:uuid, :inclusion)
    end
  end

  def existing_patients
    if patient_first_name.blank? || patient_last_name.blank? ||
         patient_date_of_birth.nil?
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

  def new_patient_attributes
    {
      address_postcode: patient_postcode,
      date_of_birth: patient_date_of_birth,
      birth_academic_year: patient_birth_academic_year,
      family_name: patient_last_name,
      given_name: patient_first_name,
      gender_code: patient_gender_code,
      nhs_number: patient_nhs_number,
      school: nil,
      home_educated: false
    }.compact
  end

  def school_urn_inclusion
    unless Location.school.exists?(urn: school_urn) ||
             school_urn.in?([SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN])
      errors.add(:school_urn, :inclusion)
    end
  end
end
