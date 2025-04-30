# frozen_string_literal: true

class PatientImportRow
  include ActiveModel::Model

  validate :validate_date_of_birth,
           :validate_existing_patients,
           :validate_first_name,
           :validate_gender_code,
           :validate_last_name,
           :validate_nhs_number,
           :validate_parent_1_email,
           :validate_parent_1_phone,
           :validate_parent_1_relationship,
           :validate_parent_2_email,
           :validate_parent_2_phone,
           :validate_parent_2_relationship,
           :validate_year_group

  def initialize(data:, organisation:, year_groups:)
    @data = data
    @organisation = organisation
    @year_groups = year_groups
  end

  def to_patient
    return unless valid?

    attributes = {
      address_line_1: address_line_1&.to_s,
      address_line_2: address_line_2&.to_s,
      address_postcode: address_postcode&.to_postcode,
      address_town: address_town&.to_s,
      birth_academic_year: birth_academic_year_value,
      date_of_birth: date_of_birth.to_date,
      family_name: last_name.to_s,
      gender_code: gender_code_value,
      given_name: first_name.to_s,
      nhs_number: nhs_number_value,
      preferred_family_name: preferred_last_name&.to_s,
      preferred_given_name: preferred_first_name&.to_s,
      registration: registration&.to_s
    }.compact

    if (existing_patient = existing_patients.first)
      unless stage_registration?
        existing_patient.registration = attributes.delete(:registration)
      end

      if attributes[:gender_code].in?(%w[male female not_specified]) &&
           !existing_patient.gender_code.in?(%w[male female not_specified]) &&
           attributes[:gender_code] != existing_patient.gender_code
        existing_patient.gender_code = attributes.delete(:gender_code)
      end

      if address_postcode.present? &&
           address_postcode.to_postcode != existing_patient.address_postcode
        attributes.merge!(
          address_line_1: address_line_1&.to_s,
          address_line_2: address_line_2&.to_s,
          address_town: address_town&.to_s
        )
      end

      existing_patient.stage_changes(attributes)

      existing_patient
    else
      Patient.new(attributes.merge(home_educated: false))
    end
  end

  def to_school_move(patient)
    if patient.new_record? || patient.school != school ||
         patient.home_educated != home_educated || patient.organisation.nil?
      school_move =
        if school
          SchoolMove.find_or_initialize_by(patient:, school:)
        else
          SchoolMove.find_or_initialize_by(
            patient:,
            home_educated:,
            organisation:
          )
        end

      school_move.tap { _1.source = school_move_source }
    end
  end

  def to_parents
    return unless valid?

    parents = [
      if parent_1_exists?
        {
          email: parent_1_email_value,
          full_name: parent_1_name&.to_s,
          phone: parent_1_phone_value
        }
      end,
      if parent_2_exists?
        {
          email: parent_2_email_value,
          full_name: parent_2_name&.to_s,
          phone: parent_2_phone_value
        }
      end
    ].compact

    parents.map do |attributes|
      email = attributes[:email]
      phone = attributes[:phone]
      full_name = attributes[:full_name]

      parent =
        Parent.match_existing(
          patient: existing_patients.first,
          email:,
          phone:,
          full_name:
        ) || Parent.new

      parent.email = attributes[:email] if attributes[:email]
      parent.full_name = attributes[:full_name] if attributes[:full_name]
      parent.phone = attributes[:phone] if attributes[:phone]
      parent.phone_receive_updates = false if parent.phone.blank?

      parent
    end
  end

  def to_parent_relationships(parents, patient)
    return unless valid?

    parent_relationships = [
      if parent_1_exists?
        parent_relationship_attributes(parent_1_relationship&.to_s)
      end,
      if parent_2_exists?
        parent_relationship_attributes(parent_2_relationship&.to_s)
      end
    ].compact

    parents
      .zip(parent_relationships)
      .map do |parent, attributes|
        ParentRelationship
          .find_or_initialize_by(parent:, patient:)
          .tap { _1.assign_attributes(attributes) }
      end
  end

  def nhs_number = @data[:child_nhs_number]

  def first_name = @data[:child_first_name]

  def last_name = @data[:child_last_name]

  def preferred_first_name = @data[:child_preferred_first_name]

  def preferred_last_name = @data[:child_preferred_last_name]

  def date_of_birth = @data[:child_date_of_birth]

  def year_group = @data[:child_year_group]

  def registration = @data[:child_registration]

  def gender_code = @data[:child_gender]

  def address_line_1 = @data[:child_address_line_1]

  def address_line_2 = @data[:child_address_line_2]

  def address_town = @data[:child_town]

  def address_postcode = @data[:child_postcode]

  def parent_1_name = @data[:parent_1_name]

  def parent_1_relationship = @data[:parent_1_relationship]

  def parent_1_email = @data[:parent_1_email]

  def parent_1_phone = @data[:parent_1_phone]

  def parent_2_name = @data[:parent_2_name]

  def parent_2_relationship = @data[:parent_2_relationship]

  def parent_2_email = @data[:parent_2_email]

  def parent_2_phone = @data[:parent_2_phone]

  def nhs_number_value
    nhs_number&.to_s&.gsub(/\s/, "")
  end

  attr_reader :organisation, :year_groups

  private

  def parent_1_exists?
    [parent_1_name, parent_1_email, parent_1_phone].any?(&:present?)
  end

  def parent_2_exists?
    [parent_2_name, parent_2_email, parent_2_phone].any?(&:present?)
  end

  def parent_relationship_attributes(relationship)
    case relationship&.downcase
    when nil, "unknown"
      { type: "unknown" }
    when "mother", "mum"
      { type: "mother" }
    when "father", "dad"
      { type: "father" }
    when "guardian"
      { type: "guardian" }
    else
      { type: "other", other_name: relationship }
    end
  end

  def existing_patients
    if first_name.blank? || last_name.blank? || date_of_birth&.to_date.nil?
      return
    end

    Patient.match_existing(
      nhs_number: nhs_number_value,
      given_name: first_name.to_s,
      family_name: last_name.to_s,
      date_of_birth: date_of_birth.to_date,
      address_postcode: address_postcode&.to_postcode&.to_s
    )
  end

  def birth_academic_year_value
    if year_group.present?
      year_group.to_i&.to_birth_academic_year
    else
      date_of_birth&.to_date&.academic_year
    end
  end

  def gender_code_value
    gender_code&.to_s&.downcase&.gsub(" ", "_")
  end

  def parent_1_email_value
    parent_1_email&.to_s&.downcase
  end

  def parent_2_email_value
    parent_2_email&.to_s&.downcase
  end

  def parent_1_phone_value
    parent_1_phone&.to_s&.gsub(/\s/, "")
  end

  def parent_2_phone_value
    parent_2_phone&.to_s&.gsub(/\s/, "")
  end

  def validate_date_of_birth
    if date_of_birth.nil?
      errors.add(:base, "<code>CHILD_DATE_OF_BIRTH</code> is missing")
    elsif date_of_birth.blank?
      errors.add(date_of_birth.header, "is required but missing")
    elsif date_of_birth.to_date.nil?
      errors.add(date_of_birth.header, "should be formatted as YYYY-MM-DD")
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

  def validate_first_name
    if first_name.nil?
      errors.add(:base, "<code>CHILD_FIRST_NAME</code> is missing")
    elsif first_name.blank?
      errors.add(first_name.header, "is required but missing")
    end
  end

  def validate_gender_code
    if gender_code.present? &&
         !Patient.gender_codes.keys.include?(gender_code_value)
      errors.add(gender_code.header, "is not a valid gender code")
    end
  end

  def validate_last_name
    if last_name.nil?
      errors.add(:base, "<code>CHILD_LAST_NAME</code> is missing")
    elsif last_name.blank?
      errors.add(last_name.header, "is required but missing")
    end
  end

  def validate_nhs_number
    return if nhs_number.blank?

    NHSNumberValidator.new(
      allow_blank: true,
      message: "should be a valid NHS number with 10 characters",
      attributes: [nhs_number.header]
    ).validate_each(self, nhs_number.header, nhs_number_value)
  end

  def validate_parent_1_email
    return if parent_1_email.blank?

    NotifySafeEmailValidator.new(
      allow_blank: true,
      message: "should be a valid email address, like j.doe@example.com",
      attributes: [parent_1_email.header]
    ).validate_each(self, parent_1_email.header, parent_1_email_value)
  end

  def validate_parent_1_phone
    return if parent_1_phone.blank?

    PhoneValidator.new(
      allow_blank: true,
      message:
        "should be a valid phone number, like 01632 960 001, 07700 900 982 or +44 808 157 0192",
      attributes: [parent_1_phone.header]
    ).validate_each(self, parent_1_phone.header, parent_1_phone_value)
  end

  def validate_parent_1_relationship
    if parent_1_relationship.present? && !parent_1_exists?
      errors.add(parent_1_relationship.header, "must be blank")
    end
  end

  def validate_parent_2_email
    return if parent_2_email.blank?

    NotifySafeEmailValidator.new(
      allow_blank: true,
      message: "should be a valid email address, like j.doe@example.com",
      attributes: [parent_2_email.header]
    ).validate_each(self, parent_2_email.header, parent_2_email_value)
  end

  def validate_parent_2_phone
    return if parent_2_phone.blank?

    PhoneValidator.new(
      allow_blank: true,
      message:
        "should be a valid phone number, like 01632 960 001, 07700 900 982 or +44 808 157 0192",
      attributes: [parent_2_phone.header]
    ).validate_each(self, parent_2_phone.header, parent_2_phone_value)
  end

  def validate_parent_2_relationship
    if parent_2_relationship.present? && !parent_2_exists?
      errors.add(parent_2_relationship.header, "must be blank")
    end
  end

  def validate_year_group
    field = year_group.presence || date_of_birth

    year_group_value = birth_academic_year_value&.to_year_group

    if year_group_value.nil?
      # We only need to add a validation error here is the file had an
      # explicit year group, since otherwise the year group comes from the
      # date of birth. If the date of birth is missing, there would already
      # be a validation error for that.

      if year_group.present?
        errors.add(field.header, "is not a valid year group")
      end

      return
    end

    unless year_group_value.in?(year_groups)
      errors.add(field.header, "is not part of this programme")
    end
  end
end
