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
#  home_educated            :boolean
#  last_name                :string
#  nhs_number               :string
#  pending_changes          :jsonb            not null
#  sent_consent_at          :datetime
#  sent_reminder_at         :datetime
#  session_reminder_sent_at :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  school_id                :bigint
#
# Indexes
#
#  index_patients_on_nhs_number  (nhs_number) UNIQUE
#  index_patients_on_school_id   (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (school_id => locations.id)
#
class Patient < ApplicationRecord
  include AgeConcern
  include PendingChangesConcern

  audited

  belongs_to :school, class_name: "Location", optional: true

  has_many :consents
  has_many :parent_relationships
  has_many :patient_sessions

  has_many :sessions, through: :patient_sessions
  has_many :triage, through: :patient_sessions
  has_many :vaccination_records, through: :patient_sessions
  has_many :parents, through: :parent_relationships
  has_many :programmes, through: :sessions

  has_and_belongs_to_many :cohort_imports
  has_and_belongs_to_many :immunisation_imports

  # https://www.datadictionary.nhs.uk/attributes/person_gender_code.html
  enum :gender_code, { not_known: 0, male: 1, female: 2, not_specified: 9 }

  scope :consent_not_sent, -> { where(sent_consent_at: nil) }
  scope :reminder_not_sent, -> { where(sent_reminder_at: nil) }

  scope :without_consent,
        -> { includes(:consents).where(consents: { id: nil }) }
  scope :needing_consent_reminder, -> { without_consent.reminder_not_sent }
  scope :not_reminded_about_session, -> { where(session_reminder_sent_at: nil) }

  scope :active,
        -> do
          where(
            PatientSession.active.where("patient_id = patients.id").arel.exists
          )
        end

  scope :matching_three_of,
        ->(first_name:, last_name:, date_of_birth:, address_postcode:) do
          where(first_name:, last_name:, date_of_birth:)
            .or(Patient.where(first_name:, last_name:, address_postcode:))
            .or(Patient.where(first_name:, date_of_birth:, address_postcode:))
            .or(Patient.where(last_name:, date_of_birth:, address_postcode:))
        end

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true
  validates :nhs_number,
            uniqueness: true,
            format: {
              with: /\A(?:\d\s*){10}\z/
            },
            allow_nil: true
  validates :school, absence: true, if: :home_educated
  validate :school_is_correct_type

  encrypts :first_name,
           :last_name,
           :common_name,
           :address_postcode,
           :nhs_number,
           deterministic: true

  encrypts :address_line_1, :address_line_2, :address_town

  before_save :remove_spaces_from_nhs_number

  def self.find_existing(
    nhs_number:,
    first_name:,
    last_name:,
    date_of_birth:,
    address_postcode:
  )
    if nhs_number.present? && (patient = Patient.find_by(nhs_number:)).present?
      return [patient]
    end

    Patient.matching_three_of(
      first_name:,
      last_name:,
      date_of_birth:,
      address_postcode:
    ).to_a
  end

  def relationship_to(parent:)
    parent_relationships.find { _1.parent == parent }
  end

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

  def school_is_correct_type
    location = school
    if location && !location.school?
      errors.add(:school, "must be a school location type")
    end
  end
end
