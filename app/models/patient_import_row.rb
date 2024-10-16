# frozen_string_literal: true

class PatientImportRow
  include ActiveModel::Model

  validates :date_of_birth, presence: true
  validates :existing_patients, length: { maximum: 1 }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :nhs_number, length: { is: 10 }, allow_blank: true
  validates :gender_code, inclusion: { in: Patient.gender_codes.keys }
  validates :year_group,
            inclusion: {
              in: :year_groups
            },
            if: -> { date_of_birth.present? }

  with_options if: :parent_1_exists? do
    validates :parent_1_name, presence: true
    validates :parent_1_relationship, presence: true
    validates :parent_1_email, presence: true, notify_safe_email: true
    validates :parent_1_phone, phone: { allow_blank: true }
  end

  with_options if: :parent_2_exists? do
    validates :parent_2_name, presence: true
    validates :parent_2_relationship, presence: true
    validates :parent_2_email, presence: true, notify_safe_email: true
    validates :parent_2_phone, phone: { allow_blank: true }
  end

  def initialize(data:, team:, year_groups:)
    @data = data
    @team = team
    @year_groups = year_groups
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
      Parent
        .create_with(recorded_at: Time.zone.now)
        .find_or_initialize_by(attributes.slice(:email, :full_name))
        .tap do |parent|
          parent.assign_attributes(
            phone: attributes[:phone],
            phone_receive_updates:
              (
                if attributes[:phone].present?
                  parent.phone_receive_updates
                else
                  false
                end
              )
          )
        end
    end
  end

  def to_patient
    return unless valid?

    attributes = {
      address_line_1:,
      address_line_2:,
      address_postcode:,
      address_town:,
      cohort:,
      common_name:,
      date_of_birth:,
      family_name: last_name,
      gender_code:,
      given_name: first_name,
      home_educated:,
      nhs_number:,
      registration:,
      school:
    }

    if (existing_patient = existing_patients.first)
      # We need to handle given_name and family_name differently because we store it encrypted and lowercased.
      # Without this, assign_attributes compares the lowercased version with the new version, and thinks
      # the model changed when it hasn't really.

      if existing_patient.given_name != attributes[:given_name]
        existing_patient.given_name = attributes[:given_name]
      end

      if existing_patient.family_name != attributes[:family_name]
        existing_patient.family_name = attributes[:family_name]
      end

      existing_patient.assign_attributes(
        attributes.except(:family_name, :given_name)
      )

      existing_patient
    else
      Patient.new(attributes)
    end
  end

  def to_parent_relationships(parents, patient)
    return unless valid?

    parent_relationships =
      [parent_1_relationship, parent_2_relationship].compact_blank.map do
        parent_relationship_attributes(_1)
      end

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

  def common_name
    @data["CHILD_COMMON_NAME"]&.strip.presence
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
    @data["CHILD_GENDER"]&.strip&.downcase&.gsub(" ", "_") || "not_known"
  end

  def address_line_1
    @data["CHILD_ADDRESS_LINE_1"]&.strip
  end

  def address_line_2
    @data["CHILD_ADDRESS_LINE_2"]&.strip
  end

  def address_town
    @data["CHILD_TOWN"]&.strip
  end

  def address_postcode
    @data["CHILD_POSTCODE"]&.strip&.presence
  end

  def parent_1_name
    @data["PARENT_1_NAME"]&.strip
  end

  def parent_1_relationship
    @data["PARENT_1_RELATIONSHIP"]&.strip
  end

  def parent_1_email
    @data["PARENT_1_EMAIL"]&.downcase&.strip
  end

  def parent_1_phone
    @data["PARENT_1_PHONE"]&.gsub(/\s/, "")
  end

  def parent_2_name
    @data["PARENT_2_NAME"]&.strip
  end

  def parent_2_relationship
    @data["PARENT_2_RELATIONSHIP"]&.strip
  end

  def parent_2_email
    @data["PARENT_2_EMAIL"]&.downcase&.strip
  end

  def parent_2_phone
    @data["PARENT_2_PHONE"]&.gsub(/\s/, "")
  end

  attr_reader :team, :year_groups

  private

  delegate :year_group, to: :date_of_birth, allow_nil: true

  def cohort
    @cohort ||=
      Cohort.find_or_create_by!(
        birth_academic_year: date_of_birth.academic_year,
        team:
      )
  end

  def parent_1_exists?
    [parent_1_name, parent_1_relationship, parent_1_email, parent_1_phone].any?(
      &:present?
    )
  end

  def parent_2_exists?
    [parent_2_name, parent_2_relationship, parent_2_email, parent_2_phone].any?(
      &:present?
    )
  end

  def parent_relationship_attributes(relationship)
    case relationship.downcase
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

    @existing_patients ||=
      Patient.match_existing(
        nhs_number:,
        given_name: first_name,
        family_name: last_name,
        date_of_birth:,
        address_postcode:
      )
  end
end
