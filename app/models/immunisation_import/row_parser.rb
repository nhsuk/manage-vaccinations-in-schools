# frozen_string_literal: true

class ImmunisationImport::RowParser
  def initialize(data)
    @data = data
  end

  def administered
    if (vaccinated = value("VACCINATED", downcase: true)).present?
      if "yes".start_with?(vaccinated)
        true
      elsif "no".start_with?(vaccinated)
        false
      end
    elsif value("VACCINE_GIVEN").present?
      true
    end
  end

  def batch_expiry = parse_date("BATCH_EXPIRY_DATE")

  def batch_name = value("BATCH_NUMBER")

  def care_setting = parse_integer("CARE_SETTING")

  def clinic_name = value("CLINIC_NAME")

  def date_of_vaccination = parse_date("DATE_OF_VACCINATION")

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
    DELIVERY_SITES[value("ANATOMICAL_SITE", downcase: true)]
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
    integer_value = parse_integer("DOSE_SEQUENCE")
    return integer_value unless integer_value.nil?

    value("DOSE_SEQUENCE", upcase: true, remove_whitespace: true)
  end

  def notes = value("NOTES")

  def offline_recording? = value("SESSION_ID").present?

  def patient_date_of_birth = parse_date("PERSON_DOB")

  def patient_family_name = value("PERSON_SURNAME")

  def patient_gender_code
    gender_code_with_spaces =
      value("PERSON_GENDER_CODE", downcase: true) ||
        value("PERSON_GENDER", downcase: true)
    gender_code_with_spaces&.gsub(" ", "_")
  end

  def patient_given_name = value("PERSON_FORENAME")

  def patient_nhs_number
    value("NHS_NUMBER", remove_whitespace: true)
  end

  def patient_postcode
    if (postcode = value("PERSON_POSTCODE")).present?
      UKPostcode.parse(postcode).to_s
    end
  end

  def patient_postcode_provided?
    value("PERSON_POSTCODE").present?
  end

  def performed_by_email
    value("PERFORMING_PROFESSIONAL_EMAIL")
  end

  def performed_by_family_name
    value("PERFORMING_PROFESSIONAL_SURNAME")
  end

  def performed_by_given_name
    value("PERFORMING_PROFESSIONAL_FORENAME")
  end

  def performed_ods_code
    value("ORGANISATION_CODE", upcase: true)
  end

  def programme_name = value("PROGRAMME")

  REASONS_NOT_VACCINATED = {
    "refused" => :refused,
    "unwell" => :not_well,
    "vaccination contraindicated" => :contraindications,
    "already had elsewhere" => :already_had,
    "did not attend" => :absent_from_session,
    "absent from school" => :absent_from_school
  }.freeze

  def reason_not_vaccinated
    REASONS_NOT_VACCINATED[value("REASON_NOT_VACCINATED", downcase: true)]
  end

  def school_name = value("SCHOOL_NAME")

  def school_urn = value("SCHOOL_URN")

  def session_id = parse_integer("SESSION_ID")

  def time_of_vaccination = parse_time("TIME_OF_VACCINATION")

  def time_of_vaccination_provided?
    value("TIME_OF_VACCINATION").present?
  end

  def uuid = value("UUID")

  def vaccine_name = value("VACCINE_GIVEN")

  private

  attr_reader :data

  def value(key, downcase: false, upcase: false, remove_whitespace: false)
    parsed_value = data[key]&.strip&.presence
    return nil if parsed_value.nil?

    parsed_value = parsed_value.downcase if downcase
    parsed_value = parsed_value.upcase if upcase
    parsed_value = parsed_value.gsub(/\s/, "") if remove_whitespace

    parsed_value
  end

  def parse_integer(key)
    Integer(value(key))
  rescue ArgumentError, TypeError
    nil
  end

  DATE_FORMATS = %w[%Y%m%d %Y-%m-%d %d/%m/%Y].freeze

  def parse_date(key)
    string_value = value(key)
    return nil if string_value.nil?

    parsed_dates =
      DATE_FORMATS.lazy.filter_map do |format|
        Date.strptime(string_value, format)
      rescue ArgumentError, TypeError
        nil
      end

    parsed_dates.first
  end

  TIME_FORMATS = %w[%H:%M:%S %H:%M %H%M%S %H%M %H].freeze

  def parse_time(key)
    string_value = value(key)
    return nil if string_value.nil?

    parsed_times =
      TIME_FORMATS.lazy.filter_map do |format|
        Time.zone.strptime(string_value, format)
      rescue ArgumentError, TypeError
        nil
      end

    parsed_times.first
  end
end
