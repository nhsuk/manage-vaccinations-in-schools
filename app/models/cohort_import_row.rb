# frozen_string_literal: true

class CohortImportRow
  include ActiveModel::Model

  attr_accessor :school_urn,
                :school_name,
                :parent_name,
                :parent_relationship,
                :parent_email,
                :parent_phone,
                :child_first_name,
                :child_last_name,
                :child_common_name,
                :child_date_of_birth,
                :child_address_line_1,
                :child_address_line_2,
                :child_address_town,
                :child_address_postcode,
                :child_nhs_number

  validates :school_urn, presence: true
  validate :school_urn_is_valid, if: -> { school_urn.present? }
  validates :parent_name, presence: true
  validates :parent_relationship, presence: true
  validates :parent_email, presence: true
  validates :parent_email,
            notify_safe_email: true,
            if: -> { parent_email.present? }
  validates :parent_phone, phone: true, if: -> { parent_phone.present? }
  validates :child_first_name, presence: true
  validates :child_last_name, presence: true
  validates :child_date_of_birth, presence: true
  validates :child_date_of_birth,
            format: {
              with: /\A(\d{4}-\d{2}-\d{2}|\d{2}\/\d{2}\/\d{4})\z/
            },
            if: -> { child_date_of_birth.present? }
  validates :child_address_line_1, presence: true
  validates :child_address_town, presence: true
  validates :child_address_postcode, presence: true
  validates :child_address_postcode,
            postcode: true,
            if: -> { child_address_postcode.present? }
  validates :child_nhs_number, presence: true
  validates :child_nhs_number,
            format: {
              with: /\A(?:\d\s*){10}\z/
            },
            if: -> { child_nhs_number.present? }

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
    {
      email: parent_email,
      name: parent_name,
      phone: parent_phone,
      recorded_at: Time.zone.now
    }.merge(parent_relationship_hash)
  end

  private

  def common_name
    child_common_name
  end

  def date_of_birth
    Date.parse(child_date_of_birth)
  end

  def first_name
    child_first_name
  end

  def last_name
    child_last_name
  end

  def nhs_number
    child_nhs_number&.gsub(/\s/, "")
  end

  def address_line_1
    child_address_line_1
  end

  def address_line_2
    child_address_line_2
  end

  def address_town
    child_address_town
  end

  def address_postcode
    child_address_postcode
  end

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

  def school_urn_is_valid
    Location.find_by!(urn: school_urn)
  rescue ActiveRecord::RecordNotFound
    errors.add(:school_urn, :invalid)
  end
end
