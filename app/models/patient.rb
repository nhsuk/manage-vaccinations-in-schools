# == Schema Information
#
# Table name: patients
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  common_name               :string
#  date_of_birth             :date
#  first_name                :string
#  last_name                 :string
#  nhs_number                :string
#  parent_email              :string
#  parent_name               :string
#  parent_phone              :string
#  parent_relationship       :integer
#  parent_relationship_other :string
#  sent_consent_at           :datetime
#  sent_reminder_at          :datetime
#  session_reminder_sent_at  :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  location_id               :bigint
#
# Indexes
#
#  index_patients_on_location_id  (location_id)
#  index_patients_on_nhs_number   (nhs_number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#
class Patient < ApplicationRecord
  include AgeConcern

  audited

  belongs_to :location, optional: true
  belongs_to :registration, optional: true
  has_many :patient_sessions
  has_many :sessions, through: :patient_sessions
  has_many :triage, through: :patient_sessions
  has_many :consents

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
            presence: true,
            uniqueness: true,
            format: {
              with: /\A(?:\d\s*){10}\z/
            }

  encrypts :first_name,
           :last_name,
           :common_name,
           :address_postcode,
           deterministic: true

  encrypts :nhs_number,
           :parent_email,
           :parent_name,
           :parent_phone,
           :parent_relationship_other,
           :address_line_1,
           :address_line_2,
           :address_town

  before_save :remove_spaces_from_nhs_number

  def full_name
    "#{first_name} #{last_name}"
  end

  def as_json(options = {})
    super.merge("full_name" => full_name, "age" => age)
  end

  def draft_vaccination_records_for_session(session)
    patient_sessions
      .find_by_session_id(session.id)
      .vaccination_records
      .rewhere(recorded_at: nil)
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
