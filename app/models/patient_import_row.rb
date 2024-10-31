# frozen_string_literal: true

class PatientImportRow
  include ActiveModel::Model

  validates :date_of_birth, presence: true
  validates :existing_patients, length: { maximum: 1 }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :nhs_number, length: { is: 10 }, allow_blank: true
  validates :gender_code,
            inclusion: {
              in: Patient.gender_codes.keys,
              allow_nil: true
            }
  validates :year_group,
            inclusion: {
              in: :year_groups
            },
            if: -> { date_of_birth.present? }
  validates :address_postcode, postcode: true

  validates :parent_1_email, notify_safe_email: { allow_blank: true }
  validates :parent_1_phone, phone: { allow_blank: true }
  validates :parent_1_relationship, absence: true, unless: :parent_1_exists?

  validates :parent_2_email, notify_safe_email: { allow_blank: true }
  validates :parent_2_phone, phone: { allow_blank: true }
  validates :parent_2_relationship, absence: true, unless: :parent_2_exists?

  def initialize(data:, organisation:, year_groups:)
    @data = data
    @organisation = organisation
    @year_groups = year_groups
  end

  def to_patient
    return unless valid?

    attributes = {
      address_line_1:,
      address_line_2:,
      address_postcode:,
      address_town:,
      date_of_birth:,
      family_name: last_name,
      gender_code:,
      given_name: first_name,
      home_educated:,
      nhs_number:,
      preferred_family_name: preferred_last_name,
      preferred_given_name: preferred_first_name,
      registration:
    }.compact.merge(cohort_id: cohort&.id, school_id: school&.id)

    if (existing_patient = existing_patients.first)
      existing_patient.stage_changes(attributes)
      existing_patient
    else
      Patient.new(attributes)
    end
  end

  def to_parents
    return unless valid?

    parents = [
      if parent_1_exists?
        {
          email: parent_1_email,
          full_name: parent_1_name,
          phone: parent_1_phone
        }
      end,
      if parent_2_exists?
        {
          email: parent_2_email,
          full_name: parent_2_name,
          phone: parent_2_phone
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

      parent.recorded_at = Time.current unless parent.recorded?

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
        parent_relationship_attributes(parent_1_relationship)
      end,
      if parent_2_exists?
        parent_relationship_attributes(parent_2_relationship)
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

  def nhs_number
    @data["CHILD_NHS_NUMBER"]&.gsub(/\s/, "").presence
  end

  def first_name
    @data["CHILD_FIRST_NAME"]&.strip
  end

  def last_name
    @data["CHILD_LAST_NAME"]&.strip
  end

  def preferred_first_name
    @data["CHILD_PREFERRED_FIRST_NAME"]&.strip.presence
  end

  def preferred_last_name
    @data["CHILD_PREFERRED_LAST_NAME"]&.strip.presence
  end

  def date_of_birth
    Date.parse(@data["CHILD_DATE_OF_BIRTH"])
  rescue ArgumentError, TypeError
    nil
  end

  def registration
    @data["CHILD_REGISTRATION"]&.strip.presence
  end

  def gender_code
    @data["CHILD_GENDER"]&.strip&.downcase&.gsub(" ", "_").presence
  end

  def address_line_1
    @data["CHILD_ADDRESS_LINE_1"]&.strip.presence
  end

  def address_line_2
    @data["CHILD_ADDRESS_LINE_2"]&.strip.presence
  end

  def address_town
    @data["CHILD_TOWN"]&.strip.presence
  end

  def address_postcode
    @data["CHILD_POSTCODE"]&.strip.presence
  end

  def parent_1_name
    @data["PARENT_1_NAME"]&.strip.presence
  end

  def parent_1_relationship
    @data["PARENT_1_RELATIONSHIP"]&.strip.presence
  end

  def parent_1_email
    @data["PARENT_1_EMAIL"]&.downcase&.strip.presence
  end

  def parent_1_phone
    @data["PARENT_1_PHONE"]&.gsub(/\s/, "").presence
  end

  def parent_2_name
    @data["PARENT_2_NAME"]&.strip.presence
  end

  def parent_2_relationship
    @data["PARENT_2_RELATIONSHIP"]&.strip.presence
  end

  def parent_2_email
    @data["PARENT_2_EMAIL"]&.downcase&.strip.presence
  end

  def parent_2_phone
    @data["PARENT_2_PHONE"]&.gsub(/\s/, "").presence
  end

  attr_reader :organisation, :year_groups

  private

  delegate :year_group, to: :date_of_birth, allow_nil: true

  def cohort
    @cohort ||=
      Cohort.find_or_create_by!(
        birth_academic_year: date_of_birth.academic_year,
        organisation:
      )
  end

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
    return if first_name.blank? || last_name.blank? || date_of_birth.nil?

    Patient.match_existing(
      nhs_number:,
      given_name: first_name,
      family_name: last_name,
      date_of_birth:,
      address_postcode:
    )
  end
end
