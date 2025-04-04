# frozen_string_literal: true

class ImmunisationImportRow
  include ActiveModel::Model

  validate :validate_administered,
           :validate_batch_expiry,
           :validate_batch_name,
           :validate_care_setting,
           :validate_clinic_name,
           :validate_date_of_vaccination,
           :validate_delivery_site,
           :validate_dose_sequence,
           :validate_existing_patients,
           :validate_patient_date_of_birth,
           :validate_patient_first_name,
           :validate_patient_gender_code,
           :validate_patient_last_name,
           :validate_patient_nhs_number,
           :validate_patient_postcode,
           :validate_performed_by,
           :validate_performed_ods_code,
           :validate_programme_name,
           :validate_reason_not_administered,
           :validate_school_name,
           :validate_school_urn,
           :validate_session_id,
           :validate_time_of_vaccination,
           :validate_uuid,
           :validate_vaccine_name

  CARE_SETTING_SCHOOL = 1
  CARE_SETTING_COMMUNITY = 2

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

  DOSE_SEQUENCES = {
    "hpv" => {
      "1P" => 1,
      "2P" => 2,
      "3P" => 3
    },
    "menacwy" => {
      "1P" => 1,
      "1B" => 2,
      "2B" => 3
    },
    "td_ipv" => {
      "1P" => 1,
      "2P" => 2,
      "3P" => 3,
      "1B" => 4,
      "2B" => 5
    }
  }.freeze

  REASONS_NOT_ADMINISTERED = {
    "refused" => :refused,
    "unwell" => :not_well,
    "vaccination contraindicated" => :contraindications,
    "already had elsewhere" => :already_had,
    "did not attend" => :absent_from_session,
    "absent from school" => :absent_from_school
  }.freeze

  SCHOOL_URN_HOME_EDUCATED = "999999"
  SCHOOL_URN_UNKNOWN = "888888"

  attr_reader :organisation

  def initialize(data:, organisation:)
    @data = data
    @organisation = organisation
  end

  def to_vaccination_record
    return unless valid?

    outcome = (administered ? "administered" : reason_not_administered_value)

    attributes = {
      dose_sequence: dose_sequence_value,
      location_name:,
      outcome:,
      patient:,
      performed_at:,
      performed_by_user:,
      performed_ods_code: performed_ods_code&.to_s,
      programme:,
      session:
    }

    if performed_by_user.nil?
      attributes.merge!(
        performed_by_family_name: performed_by_family_name&.to_s,
        performed_by_given_name: performed_by_given_name&.to_s
      )
    end

    vaccination_record =
      if uuid.present?
        VaccinationRecord
          .joins(:organisation)
          .find_by!(organisations: { id: organisation.id }, uuid: uuid.to_s)
          .tap { _1.assign_attributes(attributes) }
      else
        VaccinationRecord.find_or_initialize_by(attributes)
      end

    if vaccination_record.persisted?
      vaccination_record.stage_changes(
        batch_id: batch&.id,
        delivery_method: delivery_method_value,
        delivery_site: delivery_site_value,
        notes: notes&.to_s,
        vaccine_id: vaccine&.id
      )
    else
      # Postgres UUID generation is skipped in bulk import
      vaccination_record.uuid = SecureRandom.uuid

      vaccination_record.batch = batch
      vaccination_record.delivery_method = delivery_method_value
      vaccination_record.delivery_site = delivery_site_value
      vaccination_record.notes = notes&.to_s
      vaccination_record.vaccine = vaccine
    end

    vaccination_record
  end

  def to_patient_session
    PatientSession.new(patient:, session:) if patient && session
  end

  def administered
    if (vaccinated = @data[:vaccinated]&.to_s&.downcase).present?
      if "yes".start_with?(vaccinated)
        true
      elsif "no".start_with?(vaccinated)
        false
      end
    elsif vaccine_name.present?
      true
    end
  end

  def batch_expiry = @data[:batch_expiry_date]

  def batch_name = @data[:batch_number]

  def care_setting = @data[:care_setting]

  def clinic_name = @data[:clinic_name]

  def date_of_vaccination = @data[:date_of_vaccination]

  def delivery_site = @data[:anatomical_site]

  def dose_sequence = @data[:dose_sequence]

  def notes = @data[:notes]

  def patient_date_of_birth = @data[:person_dob]

  def patient_first_name = @data[:person_forename]

  def patient_gender_code =
    @data[:person_gender_code].presence || @data[:person_gender]

  def patient_last_name = @data[:person_surname]

  def patient_nhs_number = @data[:nhs_number]

  def patient_postcode = @data[:person_postcode]

  def performed_by_email = @data[:performing_professional_email]

  def performed_by_family_name = @data[:performing_professional_surname]

  def performed_by_given_name = @data[:performing_professional_forename]

  def performed_ods_code = @data[:organisation_code]

  def programme_name = @data[:programme]

  def reason_not_administered = @data[:reason_not_vaccinated]

  def school_name = @data[:school_name]

  def school_urn = @data[:school_urn]

  def session_id = @data[:session_id]

  def time_of_vaccination = @data[:time_of_vaccination]

  def uuid = @data[:uuid]

  def vaccine_name = @data[:vaccine_given]

  private

  def location_name
    return unless session.nil? || session.location.generic_clinic?

    if care_setting&.to_i == CARE_SETTING_SCHOOL ||
         (care_setting.blank? && clinic_name.blank?)
      school&.name || school_name&.to_s || "Unknown"
    else
      clinic_name&.to_s || "Unknown"
    end
  end

  def performed_at
    data = date_of_vaccination.to_date
    time = time_of_vaccination&.to_time

    Time.zone.local(
      data.year,
      data.month,
      data.day,
      time&.hour || 0,
      time&.min || 0,
      time&.sec || 0
    )
  end

  def performed_by_user
    @performed_by_user ||=
      if (email = performed_by_email&.to_s)
        User.find_by(email:)
      end
  end

  def patient
    @patient ||=
      if valid?
        existing_patients.first || Patient.create!(new_patient_attributes)
      end
  end

  def school
    @school ||=
      if school_urn.present? &&
           (
             school_urn.to_s != SCHOOL_URN_HOME_EDUCATED &&
               school_urn.to_s != SCHOOL_URN_UNKNOWN
           )
        Location.school.find_by(urn: school_urn.to_s)
      end
  end

  def programme
    @programme ||= programmes_by_name[programme_name&.to_s]
  end

  def session
    @session ||=
      if (id = session_id&.to_i)
        organisation
          .sessions
          .for_current_academic_year
          .includes(:location, :programmes, :session_dates)
          .find_by(id:)
      end
  end

  def vaccine
    @vaccine ||=
      organisation
        .vaccines
        .where(programme:)
        .find_by(nivs_name: vaccine_name&.to_s)
  end

  def batch
    return unless valid?

    @batch ||=
      if administered && vaccine && batch_name.present?
        Batch.create_with(archived_at: Time.current).find_or_create_by!(
          expiry: batch_expiry&.to_date,
          name: batch_name.to_s,
          organisation:,
          vaccine:
        )
      end
  end

  def programmes_by_name
    @programmes_by_name ||=
      (session || organisation)
        .programmes
        .each_with_object({}) do |programme, hash|
          programme.import_names.each { |name| hash[name] = programme }
        end
  end

  delegate :default_dose_sequence,
           :maximum_dose_sequence,
           to: :programme,
           allow_nil: true

  def offline_recording? = session_id.present?

  def existing_patients
    if patient_first_name.blank? || patient_last_name.blank? ||
         patient_date_of_birth.nil?
      return
    end

    Patient.match_existing(
      nhs_number: patient_nhs_number_value,
      given_name: patient_first_name.to_s,
      family_name: patient_last_name.to_s,
      date_of_birth: patient_date_of_birth.to_date,
      address_postcode: patient_postcode&.to_postcode
    )
  end

  def new_patient_attributes
    {
      address_postcode: patient_postcode&.to_postcode,
      date_of_birth: patient_date_of_birth.to_date,
      birth_academic_year: patient_date_of_birth.to_date.academic_year,
      family_name: patient_last_name.to_s,
      given_name: patient_first_name.to_s,
      gender_code: patient_gender_code_value,
      nhs_number: patient_nhs_number_value,
      school: nil,
      home_educated: false
    }.compact
  end

  def delivery_site_value
    DELIVERY_SITES[delivery_site&.to_s&.downcase]
  end

  def delivery_method_value
    if delivery_site_value == "nose"
      "nasal_spray"
    elsif delivery_site_value.present?
      "intramuscular"
    end
  end

  def dose_sequence_value
    value = dose_sequence&.to_s&.gsub(/\s/, "")&.upcase

    return default_dose_sequence if value.blank?

    dose_sequences = DOSE_SEQUENCES[programme&.type]

    return dose_sequences[value] if dose_sequences&.include?(value)

    dose_sequence&.to_i
  end

  def patient_gender_code_value
    patient_gender_code&.to_s&.downcase&.gsub(" ", "_")
  end

  def patient_nhs_number_value
    patient_nhs_number&.to_s&.gsub(/\s/, "")
  end

  def reason_not_administered_value
    REASONS_NOT_ADMINISTERED[reason_not_administered&.to_s&.downcase]
  end

  def validate_administered
    unless [true, false].include?(administered)
      errors.add(:administered, :inclusion)
    end
  end

  EARLIEST_BATCH_EXPIRY = Date.new(Date.current.year - 15, 1, 1)
  LATEST_BATCH_EXPIRY = Date.new(Date.current.year + 15, 1, 1)

  def validate_batch_expiry
    if administered
      if batch_expiry.present?
        if (date = batch_expiry.to_date)
          if date > LATEST_BATCH_EXPIRY
            errors.add(:batch_expiry, :less_than, count: LATEST_BATCH_EXPIRY)
          elsif date < EARLIEST_BATCH_EXPIRY
            errors.add(
              :batch_expiry,
              :greater_than,
              count: EARLIEST_BATCH_EXPIRY
            )
          end
        else
          errors.add(:batch_expiry, :invalid)
        end
      elsif offline_recording?
        errors.add(:batch_expiry, :blank)
      end
    elsif batch_expiry.present?
      errors.add(:batch_expiry, :present)
    end
  end

  def validate_batch_name
    if administered
      errors.add(:batch_name, :blank) if batch_name.blank? && offline_recording?
    elsif batch_name.present?
      errors.add(:batch_name, :present)
    end
  end

  def validate_care_setting
    return if care_setting.blank?

    if care_setting.to_i.nil?
      errors.add(:care_setting, :invalid)
    elsif ![CARE_SETTING_SCHOOL, CARE_SETTING_COMMUNITY].include?(
          care_setting.to_i
        )
      errors.add(:care_setting, :inclusion)
    end
  end

  def validate_clinic_name
    if offline_recording? && care_setting&.to_i == CARE_SETTING_COMMUNITY
      if clinic_name.blank?
        errors.add(:clinic_name, :blank)
      elsif !organisation.community_clinics.exists?(name: clinic_name.to_s)
        errors.add(:clinic_name, :inclusion)
      end
    end
  end

  def validate_date_of_vaccination
    if date_of_vaccination.blank?
      errors.add(:date_of_vaccination, :blank)
    elsif date_of_vaccination.to_date.nil?
      errors.add(:date_of_vaccination, :invalid)
    else
      if patient_date_of_birth&.to_date
        if date_of_vaccination.to_date.future?
          errors.add(
            :date_of_vaccination,
            :less_than_or_equal_to,
            count: Date.current
          )
        elsif date_of_vaccination.to_date < patient_date_of_birth.to_date
          errors.add(
            :date_of_vaccination,
            :greater_than,
            count: patient_date_of_birth
          )
        end
      end

      if offline_recording? && session &&
           !session.dates.include?(date_of_vaccination.to_date)
        errors.add(:date_of_vaccination, :inclusion)
      end
    end
  end

  def validate_delivery_site
    if administered
      if delivery_site.present?
        if delivery_site_value.blank?
          errors.add(:delivery_site, :invalid)
        elsif offline_recording? && vaccine
          unless vaccine.available_delivery_sites.include?(delivery_site_value)
            errors.add(:delivery_site, :inclusion)
          end
        end
      elsif offline_recording?
        errors.add(:delivery_site, :blank)
      end
    elsif delivery_site.present?
      errors.add(:delivery_site, :present)
    end
  end

  def validate_dose_sequence
    if dose_sequence.present?
      if offline_recording? && default_dose_sequence.nil?
        errors.add(:dose_sequence, :present)
      elsif dose_sequence_value.nil?
        errors.add(:dose_sequence, :invalid)
      elsif maximum_dose_sequence
        if dose_sequence_value < 1
          errors.add(:dose_sequence, :greater_than_or_equal_to, count: 1)
        elsif dose_sequence_value > maximum_dose_sequence
          errors.add(
            :dose_sequence,
            :less_than_or_equal_to,
            count: maximum_dose_sequence
          )
        end
      end
    elsif administered && offline_recording? && default_dose_sequence.present?
      errors.add(:dose_sequence, :blank)
    end
  end

  def validate_existing_patients
    if existing_patients && existing_patients.length > 1
      errors.add(:existing_patients, :too_long)
    end
  end

  def validate_patient_date_of_birth
    if patient_date_of_birth.blank?
      errors.add(:patient_date_of_birth, :blank)
    elsif patient_date_of_birth.to_date.nil?
      errors.add(:patient_date_of_birth, :invalid)
    elsif patient_date_of_birth.to_date.future?
      errors.add(:patient_date_of_birth, :less_than, count: Date.current)
    end
  end

  def validate_patient_first_name
    errors.add(:patient_first_name, :blank) if patient_first_name.blank?
  end

  def validate_patient_gender_code
    if patient_gender_code.blank?
      errors.add(:patient_gender_code, :blank)
    elsif patient_gender_code_value.nil?
      errors.add(:patient_gender_code, :invalid)
    elsif !Patient.gender_codes.keys.include?(patient_gender_code_value)
      errors.add(:patient_gender_code, :inclusion)
    end
  end

  def validate_patient_last_name
    errors.add(:patient_last_name, :blank) if patient_last_name.blank?
  end

  def validate_patient_nhs_number
    if patient_nhs_number.present? && patient_nhs_number_value.length != 10
      errors.add(:patient_nhs_number, :invalid)
    end
  end

  def validate_patient_postcode
    if patient_postcode.present?
      if patient_postcode.to_postcode.nil?
        errors.add(:patient_postcode, :invalid)
      end
    elsif patient_nhs_number_value.blank?
      errors.add(:patient_postcode, :blank)
    end
  end

  def validate_performed_by
    if offline_recording?
      errors.add(:performed_by_email, :blank) if performed_by_user.nil?
    elsif performed_by_email.present? # previous academic years from here on
      errors.add(:performed_by_email, :inclusion) if performed_by_user.nil?
    elsif programme&.flu? # no validation required for HPV
      if performed_by_given_name.blank?
        errors.add(:performed_by_given_name, :blank)
      end
      if performed_by_family_name.blank?
        errors.add(:performed_by_family_name, :blank)
      end
    end
  end

  def validate_performed_ods_code
    if offline_recording?
      if performed_ods_code.blank?
        errors.add(:performed_ods_code, :blank)
      elsif performed_ods_code.to_s != organisation.ods_code
        errors.add(:performed_ods_code, :equal_to)
      end
    end
  end

  def validate_programme_name
    if programme_name.blank?
      errors.add(:programme_name, :blank)
    elsif !programmes_by_name.keys.include?(programme_name.to_s)
      errors.add(:programme_name, :inclusion)
    end
  end

  def validate_reason_not_administered
    if administered
      if reason_not_administered.present?
        errors.add(:reason_not_administered, :present)
      end
    elsif reason_not_administered.present?
      if reason_not_administered_value.blank?
        errors.add(:reason_not_administered, :invalid)
      end
    else
      errors.add(:reason_not_administered, :blank)
    end
  end

  def validate_school_name
    if school_name.blank? && school_urn&.to_s == SCHOOL_URN_UNKNOWN
      errors.add(:school_name, :blank)
    end
  end

  def validate_school_urn
    return if school_urn.blank?

    unless Location.school.exists?(urn: school_urn.to_s) ||
             school_urn.to_s.in?([SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN])
      errors.add(:school_urn, :inclusion)
    end
  end

  def validate_session_id
    if session_id.present?
      if session_id.to_i.nil?
        errors.add(:session_id, :invalid)
      elsif !organisation.sessions.for_current_academic_year.exists?(
            id: session_id.to_i
          )
        errors.add(:session_id, :inclusion)
      end
    end
  end

  def validate_time_of_vaccination
    return if time_of_vaccination.blank?

    if time_of_vaccination.to_time.nil?
      errors.add(:time_of_vaccination, :invalid)
    elsif date_of_vaccination&.to_date&.today?
      if time_of_vaccination.to_time.future?
        errors.add(
          :time_of_vaccination,
          :less_than_or_equal_to,
          count: Time.current
        )
      end
    end
  end

  def validate_uuid
    return if uuid.blank?

    scope =
      VaccinationRecord.joins(:organisation).where(
        organisations: {
          id: organisation.id
        },
        uuid: uuid.to_s
      )

    errors.add(:uuid, :inclusion) unless scope.exists?
  end

  def validate_vaccine_name
    if vaccine_name.present? && vaccine.nil?
      errors.add(:vaccine_name, :inclusion)
    end
  end
end
