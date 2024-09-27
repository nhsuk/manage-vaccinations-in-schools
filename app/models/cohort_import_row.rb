# frozen_string_literal: true

class CohortImportRow
  include ActiveModel::Model

  SCHOOL_URN_HOME_EDUCATED = "999999"
  SCHOOL_URN_UNKNOWN = "888888"

  validates :address_postcode, postcode: true
  validates :date_of_birth, presence: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :nhs_number, length: { is: 10 }, allow_blank: true
  validates :school_urn,
            inclusion: {
              in: -> do
                Location.school.pluck(:urn) +
                  [SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN]
              end
            }
  validate :date_of_birth_in_a_valid_year_group

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

  validate :zero_or_one_existing_patient

  def initialize(data:, team:, programme:)
    @data = data
    @team = team
    @programme = programme
  end

  def to_parents
    return unless valid?

    parents = [
      if parent_1_exists?
        { email: parent_1_email, name: parent_1_name, phone: parent_1_phone }
      end,
      if parent_2_exists?
        { email: parent_2_email, name: parent_2_name, phone: parent_2_phone }
      end
    ].compact

    parents.map do |attributes|
      Parent
        .find_or_initialize_by(attributes.slice(:email, :name))
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
      first_name:,
      home_educated:,
      last_name:,
      nhs_number:,
      school:
    }

    if (existing_patient = find_existing_patients.first)
      existing_patient.assign_attributes(attributes)
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

  def school_urn
    @data["CHILD_SCHOOL_URN"]&.strip
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

  def address_line_1
    @data["CHILD_ADDRESS_LINE_1"]&.strip
  end

  def address_line_2
    @data["CHILD_ADDRESS_LINE_2"]&.strip
  end

  def address_town
    @data["CHILD_ADDRESS_TOWN"]&.strip
  end

  def address_postcode
    @data["CHILD_ADDRESS_POSTCODE"]&.strip
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

  private

  def cohort
    @cohort ||=
      Cohort.find_or_create_by!(
        birth_academic_year: date_of_birth.academic_year,
        team: @team
      )
  end

  def school
    @school ||=
      unless [SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN].include?(school_urn)
        Location.school.find_by!(urn: school_urn)
      end
  end

  def home_educated
    if school_urn == SCHOOL_URN_UNKNOWN
      nil
    else
      school_urn == SCHOOL_URN_HOME_EDUCATED
    end
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
    case relationship
    when "Mother"
      { type: "mother" }
    when "Father"
      { type: "father" }
    when "Guardian"
      { type: "guardian" }
    else
      { type: "other", other: relationship }
    end
  end

  def date_of_birth_in_a_valid_year_group
    return if date_of_birth.nil?

    unless @programme.year_groups.include?(date_of_birth.year_group)
      errors.add(:date_of_birth, :inclusion)
    end
  end

  def find_existing_patients
    @find_existing_patients ||=
      Patient.find_existing(
        nhs_number:,
        first_name:,
        last_name:,
        date_of_birth:,
        address_postcode:
      )
  end

  def zero_or_one_existing_patient
    if find_existing_patients.count >= 2
      errors.add(:patient, :multiple_duplicate_match)
    end
  end
end
