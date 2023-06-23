# == Schema Information
#
# Table name: patients
#
#  id             :bigint           not null, primary key
#  consent        :integer
#  dob            :date
#  first_name     :text
#  gp             :integer
#  last_name      :text
#  nhs_number     :bigint
#  preferred_name :text
#  screening      :integer
#  seen           :integer
#  sex            :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_patients_on_nhs_number  (nhs_number) UNIQUE
#
class Patient < ApplicationRecord
  belongs_to :location, optional: true
  has_many :patient_sessions
  has_many :sessions, through: :patient_sessions
  has_many :triage
  has_many :consent_responses

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :dob, presence: true
  validates :nhs_number, presence: true, uniqueness: true

  enum :sex, %w[Female Male]
  enum :gp, ["Local GP"]
  enum :screening, ["Approved for vaccination"]
  enum :consent, ["Parental consent (digital)"]
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
    triage.find_or_create_by!(campaign:)
  end

  def consent_response_for_campaign(campaign)
    consent_responses.find_by(campaign:)
  end

  def as_json(options = {})
    super.merge("full_name" => full_name, "age" => age)
  end
end
