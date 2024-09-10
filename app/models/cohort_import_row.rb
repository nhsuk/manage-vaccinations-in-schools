# frozen_string_literal: true

class CohortImportRow
  include ActiveModel::Model

  validates :school_urn, inclusion: { in: -> { Location.school.pluck(:urn) } }

  validates :nhs_number, length: { is: 10 }, allow_blank: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true
  validates :address_line_1, presence: true
  validates :address_town, presence: true
  validates :address_postcode, presence: true
  validates :address_postcode, postcode: true

  validates :parent_name, presence: true
  validates :parent_relationship, presence: true
  validates :parent_email, presence: true, notify_safe_email: true
  validates :parent_phone, phone: true, if: -> { parent_phone.present? }

  def initialize(data:)
    @data = data
  end

  def to_patient
    {
      common_name:,
      date_of_birth:,
      first_name:,
      last_name:,
      nhs_number:,
      address_line_1:,
      address_line_2:,
      address_town:,
      address_postcode:
    }
  end

  def to_parent
    parent_relationship_hash.merge(
      email: parent_email,
      name: parent_name,
      phone: parent_phone
    )
  end

  def school_urn
    @data["SCHOOL_URN"]&.strip
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

  def parent_name
    @data["PARENT_NAME"]&.strip
  end

  def parent_relationship
    @data["PARENT_RELATIONSHIP"]&.strip
  end

  def parent_email
    @data["PARENT_EMAIL"]&.downcase&.strip
  end

  def parent_phone
    @data["PARENT_PHONE"]&.gsub(/\s/, "")
  end

  private

  def parent_relationship_hash
    case parent_relationship
    when "Mother"
      { relationship: "mother" }
    when "Father"
      { relationship: "father" }
    when "Guardian"
      { relationship: "guardian" }
    else
      { relationship: "other", relationship_other: parent_relationship }
    end
  end
end
