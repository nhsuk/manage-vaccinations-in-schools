# == Schema Information
#
# Table name: patients
#
#  id                        :bigint           not null, primary key
#  consent                   :integer
#  dob                       :date
#  first_name                :text
#  last_name                 :text
#  nhs_number                :bigint
#  parent_email              :text
#  parent_info_source        :text
#  parent_name               :text
#  parent_phone              :text
#  parent_relationship       :integer
#  parent_relationship_other :text
#  preferred_name            :text
#  screening                 :integer
#  seen                      :integer
#  sex                       :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_patients_on_nhs_number  (nhs_number) UNIQUE
#
class Patient < ApplicationRecord
  audited

  belongs_to :location, optional: true
  has_many :patient_sessions
  has_many :sessions, through: :patient_sessions
  has_many :triage, through: :patient_sessions
  has_many :consent_responses

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :dob, presence: true
  validates :nhs_number, presence: true, uniqueness: true

  enum :sex, %w[Female Male]
  enum :screening, ["Approved for vaccination"]
  enum :consent, ["Parental consent (digital)"]
  enum :parent_relationship, %w[mother father guardian other], prefix: true

  # TODO: Deprecate. VaccinationRecords supersede .seen
  enum :seen, ["Not yet", "Vaccinated"]

  def full_name
    "#{first_name} #{last_name}"
  end

  # TODO: Needs testing for calculations around leap years, etc.
  def age
    now = Time.zone.now.to_date
    now.year - dob.year -
      (
        if now.month > dob.month ||
             (now.month == dob.month && now.day >= dob.day)
          0
        else
          1
        end
      )
  end

  def triage_for_campaign(campaign)
    triage.to_a.find { |t| t.campaign_id == campaign.id }
  end

  def consent_response_for_campaign(campaign)
    consent_responses.to_a.find do |t|
      t.campaign_id == campaign.id && t.recorded_at.present?
    end
  end

  def as_json(options = {})
    super.merge("full_name" => full_name, "age" => age)
  end

  def vaccination_records_for_session(session)
    patient_sessions.find_by_session_id(session.id).vaccination_records
  end
end
