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
           :validate_programme,
           :validate_reason_not_administered,
           :validate_school_name,
           :validate_school_urn,
           :validate_session_id,
           :validate_time_of_vaccination,
           :validate_uuid,
           :validate_vaccine

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
      "2B" => 3,
      "1st Scheduled Booster" => 2,
      "2nd Scheduled Booster" => 3
    },
    "td_ipv" => {
      "1P" => 1,
      "2P" => 2,
      "3P" => 3,
      "1B" => 4,
      "2B" => 5,
      "1st Scheduled Booster" => 4,
      "2nd Scheduled Booster" => 5
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

  def batch_expiry = @data[:batch_expiry_date]

  def batch_name =
    @data[:batch_number].presence || @data[:vaccination_batch_number]

  def care_setting = @data[:care_setting]

  def clinic_name = @data[:clinic_name].presence || @data[:event_done_at]

  def combined_vaccination_and_dose_sequence = @data[:vaccination_type]

  def date_of_vaccination =
    @data[:date_of_vaccination].presence || @data[:event_date]

  def delivery_site = @data[:anatomical_site]

  def dose_sequence = @data[:dose_sequence]

  def location_type = @data[:event_location_type]

  def notes = @data[:notes]

  def patient_date_of_birth =
    @data[:person_dob].presence || @data[:date_of_birth]

  def patient_first_name =
    @data[:person_forename].presence || @data[:first_name]

  def patient_gender_code =
    @data[:person_gender_code].presence || @data[:person_gender].presence ||
      @data[:sex]

  def patient_last_name = @data[:person_surname].presence || @data[:surname]

  def patient_nhs_number = @data[:nhs_number]

  def patient_postcode = @data[:person_postcode].presence || @data[:postcode]

  def performed_by_email = @data[:performing_professional_email]

  def performed_by_family_name = @data[:performing_professional_surname]

  def performed_by_given_name = @data[:performing_professional_forename]

  def performed_ods_code = @data[:organisation_code]

  def programme_name = @data[:programme]

  def reason_not_administered = @data[:reason_not_vaccinated]

  def school_name =
    @data[:school_name].presence || @data[:school].presence ||
      @data[:event_done_at]

  def school_urn = @data[:school_urn].presence || @data[:school_code]

  def session_id = @data[:session_id]

  def time_of_vaccination =
    @data[:time_of_vaccination].presence || @data[:event_time]

  def uuid = @data[:uuid]

  def vaccinated = @data[:vaccinated]

  def vaccine_name = @data[:vaccine_given]

  private

  def location_name
    return unless session.nil? || session.location.generic_clinic?

    if is_school_setting? || (is_unknown_setting? && clinic_name.blank?)
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
      if school_urn.present? && school_urn.to_s != SCHOOL_URN_HOME_EDUCATED &&
           school_urn.to_s != SCHOOL_URN_UNKNOWN
        Location.school.find_by(urn: school_urn.to_s)
      end
  end

  def programme
    @programme ||=
      begin
        name =
          parsed_vaccination_description_string&.dig(:programme_name) ||
            programme_name&.to_s

        programmes_by_name[name] || vaccine&.programme
      end
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

  def vaccine_nivs_name
    parsed_vaccination_description_string&.dig(:vaccine_name) ||
      vaccine_name&.to_s
  end

  def vaccine
    @vaccine ||=
      organisation
        .vaccines
        .includes(:programme)
        .find_by(nivs_name: vaccine_nivs_name)
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

  delegate :default_dose_sequence, :maximum_dose_sequence, to: :programme

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

  def administered
    if vaccinated.present?
      if "yes".start_with?(vaccinated.to_s.downcase)
        true
      elsif "no".start_with?(vaccinated.to_s.downcase)
        false
      end
    elsif vaccine_name.present? ||
          combined_vaccination_and_dose_sequence.present?
      true
    end
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
    value =
      parsed_vaccination_description_string&.dig(:dose_sequence) ||
        dose_sequence&.to_s&.gsub(/\s/, "")&.upcase

    return default_dose_sequence if value.blank?

    return value if value.is_a?(Integer)

    dose_sequences = DOSE_SEQUENCES[programme&.type]

    return dose_sequences[value] if dose_sequences&.include?(value)

    dose_sequence&.to_i
  end

  def is_unknown_setting?
    care_setting.blank? && location_type.blank?
  end

  def is_school_setting?
    care_setting&.to_i == CARE_SETTING_SCHOOL ||
      location_type&.to_s&.downcase == "school"
  end

  def is_community_setting?
    care_setting&.to_i == CARE_SETTING_COMMUNITY ||
      (location_type.present? && location_type.to_s.downcase != "school")
  end

  def parsed_vaccination_description_string
    if combined_vaccination_and_dose_sequence.present?
      VaccinationDescriptionStringParser.call(
        combined_vaccination_and_dose_sequence.to_s
      )
    end
  end

  def patient_gender_code_value
    value = patient_gender_code&.to_s&.downcase&.gsub(" ", "_")

    if value.in?(%w[indeterminate unknown])
      "not_known"
    elsif value.in?(Patient.gender_codes.keys)
      value
    end
  end

  def patient_nhs_number_value
    patient_nhs_number&.to_s&.gsub(/\s/, "")
  end

  def reason_not_administered_value
    REASONS_NOT_ADMINISTERED[reason_not_administered&.to_s&.downcase]
  end

  def validate_administered
    return if [true, false].include?(administered)

    if vaccinated.nil?
      errors.add(:base, "<code>VACCINATED</code> is required")
    else
      errors.add(
        vaccinated.header,
        "You need to record whether the child was vaccinated or not. Enter ‘Y’ or ‘N’ in the ‘vaccinated’ column."
      )
    end
  end

  EARLIEST_BATCH_EXPIRY = Date.new(Date.current.year - 15, 1, 1)
  LATEST_BATCH_EXPIRY = Date.new(Date.current.year + 15, 1, 1)

  def validate_batch_expiry
    if administered
      if batch_expiry.present?
        if (date = batch_expiry.to_date)
          if date > LATEST_BATCH_EXPIRY
            errors.add(
              batch_expiry.header,
              "must be less than 15 years in the future"
            )
          elsif date < EARLIEST_BATCH_EXPIRY
            errors.add(batch_expiry.header, "must be more than 15 years old")
          end
        else
          errors.add(batch_expiry.header, "Enter a date in the correct format")
        end
      elsif offline_recording?
        if batch_expiry.nil?
          errors.add(:base, "<code>BATCH_EXPIRY_DATE</code> is required")
        else
          errors.add(batch_expiry.header, "Enter a batch expiry date.")
        end
      end
    elsif batch_expiry.present?
      errors.add(batch_expiry.header, "must be blank")
    end
  end

  def validate_batch_name
    if administered
      if offline_recording?
        if batch_name.nil?
          errors.add(
            :base,
            "<code>BATCH_NUMBER</code> or <code>Vaccination batch number</code> is required"
          )
        elsif batch_name.blank?
          errors.add(batch_name.header, "Enter a batch number.")
        end
      end
    elsif batch_name.present?
      errors.add(batch_name.header, "must be blank")
    end
  end

  def validate_care_setting
    return if care_setting.blank?

    if care_setting.to_i.nil?
      errors.add(care_setting.header, "Enter a valid care setting.")
    elsif ![CARE_SETTING_SCHOOL, CARE_SETTING_COMMUNITY].include?(
          care_setting.to_i
        )
      errors.add(care_setting.header, "Enter a valid care setting.")
    end
  end

  def validate_clinic_name
    if offline_recording? && is_community_setting?
      if clinic_name.nil?
        errors.add(
          :base,
          "<code>CLINIC_NAME</code> or <code>Event done at</code> is required"
        )
      elsif clinic_name.blank?
        errors.add(clinic_name.header, "Enter a clinic name")
      elsif !organisation.community_clinics.exists?(name: clinic_name.to_s)
        errors.add(clinic_name.header, "Enter a clinic name")
      end
    end
  end

  def validate_date_of_vaccination
    if date_of_vaccination.nil?
      errors.add(
        :base,
        "<code>DATE_OF_VACCINATION</code> or <code>Event date</code> is required"
      )
    elsif date_of_vaccination.blank?
      errors.add(date_of_vaccination.header, "Enter a date")
    elsif date_of_vaccination.to_date.nil?
      errors.add(
        date_of_vaccination.header,
        "Enter a date in the correct format"
      )
    else
      if patient_date_of_birth&.to_date
        if date_of_vaccination.to_date.future?
          errors.add(
            date_of_vaccination.header,
            "The vaccination date is in the future."
          )
        elsif date_of_vaccination.to_date < patient_date_of_birth.to_date
          errors.add(
            date_of_vaccination.header,
            "The vaccination date is before the date of birth."
          )
        end
      end

      if offline_recording? && session &&
           !session.dates.include?(date_of_vaccination.to_date)
        errors.add(
          date_of_vaccination.header,
          "Enter a date that matches when the vaccination session took place."
        )
      end
    end
  end

  def validate_delivery_site
    if administered
      if delivery_site.present?
        if delivery_site_value.blank?
          errors.add(delivery_site.header, "Enter a valid anatomical site.")
        elsif offline_recording? && vaccine
          unless vaccine.available_delivery_sites.include?(delivery_site_value)
            errors.add(
              delivery_site.header,
              "Enter a anatomical site that is appropriate for the vaccine."
            )
          end
        end
      elsif offline_recording?
        if delivery_site.nil?
          errors.add(:base, "<code>ANATOMICAL_SITE</code> is required")
        else
          errors.add(delivery_site.header, "Enter an anatomical site.")
        end
      end
    elsif delivery_site.present?
      errors.add(delivery_site.header, "must be blank")
    end
  end

  def validate_dose_sequence
    return if programme.nil?

    field = dose_sequence.presence || combined_vaccination_and_dose_sequence

    if dose_sequence.present? ||
         parsed_vaccination_description_string&.dig(:dose_sequence).present?
      if offline_recording? && default_dose_sequence.nil?
        errors.add(
          field.header,
          "Do not provide a dose sequence for this programme (leave blank)."
        )
      elsif dose_sequence_value.nil?
        errors.add(
          field.header,
          "The dose sequence number cannot be greater than 3. Enter a dose sequence number, for example, 1, 2 or 3."
        )
      elsif maximum_dose_sequence
        if dose_sequence_value < 1
          errors.add(field.header, "must be greater than 0")
        elsif dose_sequence_value > maximum_dose_sequence
          errors.add(field.header, "must be less than #{maximum_dose_sequence}")
        end
      end
    elsif administered && offline_recording? && default_dose_sequence.present?
      if field.nil?
        errors.add(
          :base,
          "<code>DOSE_SEQUENCE</code> or <code>Vaccination type</code> is required"
        )
      else
        errors.add(
          field.header,
          "The dose sequence number cannot be greater than 3. Enter a dose sequence number, for example, 1, 2 or 3."
        )
      end
    end
  end

  def validate_existing_patients
    if existing_patients && existing_patients.length > 1
      errors.add(
        :base,
        "Two or more possible patients match the patient first name, last name, date of birth or postcode."
      )
    end
  end

  def validate_patient_date_of_birth
    if patient_date_of_birth.nil?
      errors.add(
        :base,
        "<code>PERSON_DOB</code> or <code>Date of birth</code> is required"
      )
    elsif patient_date_of_birth.blank?
      errors.add(patient_date_of_birth.header, "Enter a date of birth.")
    elsif patient_date_of_birth.to_date.nil?
      errors.add(
        patient_date_of_birth.header,
        "Enter a date of birth in the correct format."
      )
    elsif patient_date_of_birth.to_date.future?
      errors.add(
        patient_date_of_birth.header,
        "Enter a date of birth in the past."
      )
    end
  end

  def validate_patient_first_name
    if patient_first_name.nil?
      errors.add(
        :base,
        "<code>PERSON_FORENAME</code> or <code>First name</code> is required"
      )
    elsif patient_first_name.blank?
      errors.add(patient_first_name.header, "Enter a first name.")
    end
  end

  def validate_patient_gender_code
    if patient_gender_code.nil?
      errors.add(
        :base,
        "<code>PERSON_GENDER_CODE</code>, <code>PERSON_GENDER</code> or <code>Sex</code> is required"
      )
    elsif patient_gender_code.blank?
      errors.add(patient_gender_code.header, "Enter a gender or gender code.")
    elsif patient_gender_code_value.nil?
      errors.add(
        patient_gender_code.header,
        "Enter a valid gender or gender code."
      )
    end
  end

  def validate_patient_last_name
    if patient_last_name.nil?
      errors.add(
        :base,
        "<code>PERSON_SURNAME</code> or <code>Surname</code> is required"
      )
    elsif patient_last_name.blank?
      errors.add(patient_last_name.header, "Enter a last name.")
    end
  end

  def validate_patient_nhs_number
    return if patient_nhs_number.blank?

    NHSNumberValidator.new(
      allow_blank: true,
      message: "should be a valid NHS number with 10 characters",
      attributes: [patient_nhs_number.header]
    ).validate_each(self, patient_nhs_number.header, patient_nhs_number_value)
  end

  def validate_patient_postcode
    if patient_postcode.present?
      if patient_postcode.to_postcode.nil?
        errors.add(
          patient_postcode.header,
          "Enter a valid postcode, such as SW1A 1AA."
        )
      end
    elsif patient_nhs_number_value.blank?
      if patient_postcode.nil?
        errors.add(
          :base,
          "<code>PERSON_POSTCODE</code> or <code>Postcode</code> is required"
        )
      else
        errors.add(
          patient_postcode.header,
          "Enter a valid postcode, such as SW1A 1AA."
        )
      end
    end
  end

  def validate_performed_by
    if offline_recording?
      if performed_by_user.nil?
        if performed_by_email.nil?
          errors.add(
            :base,
            "<code>PERFORMING_PROFESSIONAL_EMAIL</code> is required"
          )
        else
          errors.add(performed_by_email.header, "Enter a valid email address.")
        end
      end
    elsif performed_by_email.present? # previous academic years from here on
      if performed_by_user.nil?
        errors.add(performed_by_email.header, "Enter a valid email address")
      end
    elsif programme&.flu? # no validation required for HPV
      if performed_by_given_name.nil?
        errors.add(
          :base,
          "<code>PERFORMING_PROFESSIONAL_FORENAME</code> is required"
        )
      elsif performed_by_given_name.blank?
        errors.add(performed_by_given_name.header, "Enter a first name.")
      end

      if performed_by_family_name.nil?
        errors.add(
          :base,
          "<code>PERFORMING_PROFESSIONAL_SURNAME</code> is required"
        )
      elsif performed_by_family_name.blank?
        errors.add(performed_by_family_name.header, "Enter a last name.")
      end
    end
  end

  def validate_performed_ods_code
    if offline_recording?
      if performed_ods_code.nil?
        errors.add(:base, "<code>ORGANISATION_CODE</code> is required")
      elsif performed_ods_code.blank?
        errors.add(performed_ods_code.header, "Enter an organisation code.")
      elsif performed_ods_code.to_s != organisation.ods_code
        errors.add(
          performed_ods_code.header,
          "Enter an organisation code that matches the current organisation."
        )
      end
    end
  end

  def validate_programme
    return if programme

    field = programme_name.presence || combined_vaccination_and_dose_sequence

    if field.nil?
      errors.add(
        :base,
        "<code>PROGRAMME</code> or <code>Vaccination type</code> is required"
      )
    elsif field.blank?
      errors.add(field.header, "Enter a programme.")
    else
      errors.add(
        field.header,
        "This programme is not available in this session."
      )
    end
  end

  def validate_reason_not_administered
    if administered
      if reason_not_administered.present?
        errors.add(reason_not_administered.header, "must be blank")
      end
    elsif reason_not_administered.present?
      if reason_not_administered_value.blank?
        errors.add(reason_not_administered.header, "Enter a valid reason")
      end
    elsif reason_not_administered.nil?
      errors.add(:base, "<code>REASON_NOT_VACCINATED</code> is required")
    else
      errors.add(reason_not_administered.header, "Enter a valid reason")
    end
  end

  def validate_school_name
    if school_name.blank? && school_urn&.to_s == SCHOOL_URN_UNKNOWN
      if school_name.nil?
        errors.add(
          :base,
          "<code>SCHOOL_NAME</code> or <code>School</code> is required"
        )
      else
        errors.add(school_name.header, "Enter a school name.")
      end
    end
  end

  def validate_school_urn
    return if school_urn.blank?

    unless Location.school.exists?(urn: school_urn.to_s) ||
             school_urn.to_s.in?([SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN])
      errors.add(
        school_urn.header,
        "The school URN is not recognised. If you’ve checked the URN, " \
          "and you believe it’s valid, contact our support organisation."
      )
    end
  end

  def validate_session_id
    if session_id.present?
      if session_id.to_i.nil?
        errors.add(
          session_id.header,
          "The session ID is not recognised. Download the offline spreadsheet " \
            "and copy the session ID for this row from there, or " \
            "contact our support organisation."
        )
      elsif !organisation.sessions.for_current_academic_year.exists?(
            id: session_id.to_i
          )
        errors.add(
          session_id.header,
          "The session ID is not recognised. Download the offline spreadsheet " \
            "and copy the session ID for this row from there, or " \
            "contact our support organisation."
        )
      end
    end
  end

  def validate_time_of_vaccination
    return if time_of_vaccination.blank?

    if time_of_vaccination.to_time.nil?
      errors.add(
        time_of_vaccination.header,
        "Enter a time in the correct format."
      )
    elsif date_of_vaccination&.to_date&.today?
      if time_of_vaccination.to_time.future?
        errors.add(time_of_vaccination.header, "Enter a time in the past.")
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

    errors.add(uuid.header, "Enter an existing record.") unless scope.exists?
  end

  def validate_vaccine
    field = vaccine_name.presence || combined_vaccination_and_dose_sequence

    if vaccine
      if programme && vaccine.programme_id != programme.id
        errors.add(
          field.header,
          "is not given in the #{programme.name} programme"
        )
      end
    elsif vaccine_nivs_name.present?
      errors.add(field.header, "This vaccine is not available in this session.")
    end
  end
end
