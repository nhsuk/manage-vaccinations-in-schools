# == Schema Information
#
# Table name: patients
#
#  id                        :bigint           not null, primary key
#  consent                   :integer
#  dob                       :date
#  first_name                :text
#  last_name                 :text
#  nhs_number                :string
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
  include AgeConcern
  date_of_birth_field_for_age :dob

  audited

  belongs_to :location, optional: true
  has_many :patient_sessions
  has_many :sessions, through: :patient_sessions
  has_many :triage, through: :patient_sessions
  has_many :consents

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :dob, presence: true
  validates :nhs_number,
            presence: true,
            uniqueness: true,
            format: {
              with: /\A(?:\d\s*){10}\z/
            }

  enum :sex, %w[Female Male]
  enum :screening, ["Approved for vaccination"]
  enum :consent, ["Parental consent (digital)"]
  enum :parent_relationship, %w[mother father guardian other], prefix: true

  # TODO: Deprecate. VaccinationRecords supersede .seen
  enum :seen, ["Not yet", "Vaccinated"]

  encrypts :first_name,
           :last_name,
           :nhs_number,
           :parent_email,
           :parent_info_source,
           :parent_name,
           :parent_phone,
           :parent_relationship_other,
           :preferred_name

  before_save :remove_spaces_from_nhs_number

  def full_name
    "#{first_name} #{last_name}"
  end

  def as_json(options = {})
    super.merge("full_name" => full_name, "age" => age)
  end

  def vaccination_records_for_session(session)
    patient_sessions.find_by_session_id(session.id).vaccination_records
  end

  private

  def remove_spaces_from_nhs_number
    nhs_number&.gsub!(/\s/, "")
  end
end
