# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                       :bigint           not null, primary key
#  address_line_1           :string
#  address_line_2           :string
#  address_postcode         :string
#  address_town             :string
#  common_name              :string
#  date_of_birth            :date
#  first_name               :string
#  gender_code              :integer          default("not_known"), not null
#  last_name                :string
#  nhs_number               :string
#  sent_consent_at          :datetime
#  sent_reminder_at         :datetime
#  session_reminder_sent_at :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  imported_from_id         :bigint
#  location_id              :bigint
#  parent_id                :bigint
#
# Indexes
#
#  index_patients_on_imported_from_id  (imported_from_id)
#  index_patients_on_location_id       (location_id)
#  index_patients_on_nhs_number        (nhs_number) UNIQUE
#  index_patients_on_parent_id         (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (parent_id => parents.id)
#
class Patient < ApplicationRecord
  include AgeConcern

  audited

  belongs_to :location, optional: true
  belongs_to :parent, optional: true
  belongs_to :imported_from, class_name: "ImmunisationImport", optional: true
  has_many :patient_sessions
  has_many :sessions, through: :patient_sessions
  has_many :triage, through: :patient_sessions
  has_many :consents

  # https://www.datadictionary.nhs.uk/attributes/person_gender_code.html
  enum :gender_code, { not_known: 0, male: 1, female: 2, not_specified: 9 }

  scope :consent_not_sent, -> { where(sent_consent_at: nil) }
  scope :reminder_not_sent, -> { where(sent_reminder_at: nil) }

  scope :without_consent,
        -> { includes(:consents).where(consents: { id: nil }) }
  scope :needing_consent_reminder, -> { without_consent.reminder_not_sent }
  scope :not_reminded_about_session, -> { where(session_reminder_sent_at: nil) }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true
  validates :nhs_number,
            uniqueness: true,
            format: {
              with: /\A(?:\d\s*){10}\z/
            },
            allow_nil: true

  encrypts :first_name,
           :last_name,
           :common_name,
           :address_postcode,
           :nhs_number,
           deterministic: true

  encrypts :address_line_1, :address_line_2, :address_town

  before_save :remove_spaces_from_nhs_number

  def full_name
    "#{first_name} #{last_name}"
  end

  def as_json(options = {})
    super.merge("full_name" => full_name, "age" => age)
  end

  def year_group
    first_school_year = date_of_birth.year + 5
    first_school_year += 1 if date_of_birth.month >= 9
    Time.zone.today.year - first_school_year +
      (Time.zone.today.month >= 9 ? 1 : 0)
  end

  def address_fields
    [address_line_1, address_line_2, address_town, address_postcode].reject(
      &:blank?
    )
  end

  private

  def remove_spaces_from_nhs_number
    nhs_number&.gsub!(/\s/, "")
  end
end
