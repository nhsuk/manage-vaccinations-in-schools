# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                 :bigint           not null, primary key
#  administered       :boolean
#  delivery_method    :integer
#  delivery_site      :integer
#  dose_sequence      :integer          not null
#  exported_to_dps_at :datetime
#  notes              :text
#  reason             :integer
#  recorded_at        :datetime
#  uuid               :uuid             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  batch_id           :bigint
#  imported_from_id   :bigint
#  patient_session_id :bigint           not null
#  user_id            :bigint
#  vaccine_id         :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id            (batch_id)
#  index_vaccination_records_on_imported_from_id    (imported_from_id)
#  index_vaccination_records_on_patient_session_id  (patient_session_id)
#  index_vaccination_records_on_user_id             (user_id)
#  index_vaccination_records_on_vaccine_id          (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class VaccinationRecord < ApplicationRecord
  include WizardFormConcern

  audited associated_with: :patient_session

  attr_accessor :delivery_site_other, :todays_batch

  DELIVERY_SITE_SNOMED_CODES_AND_TERMS = {
    left_thigh: ["61396006", "Structure of left thigh (body structure)"],
    right_thigh: ["11207009", "Structure of right thigh (body structure)"],
    left_arm_upper_position: [
      "368208006",
      "Structure of left upper arm (body structure)"
    ],
    right_arm_upper_position: [
      "368209003",
      "Structure of right upper arm (body structure)"
    ],
    left_buttock: ["723979003", "Structure of left buttock (body structure)"],
    right_buttock: ["723980000", "Structure of right buttock (body structure)"],
    nose: ["279549004", "Nasal cavity structure (body structure)"]
  }.with_indifferent_access

  DELIVERY_METHOD_SNOMED_CODES_AND_TERMS = {
    intramuscular: ["78421000", "Intramuscular route (qualifier value)"],
    subcutaneous: ["34206005", "Subcutaneous route (qualifier value)"],
    nasal_spray: ["46713006", "Nasal route (qualifier value)"]
  }.with_indifferent_access

  belongs_to :patient_session
  belongs_to :imported_from, class_name: "ImmunisationImport", optional: true
  belongs_to :batch, optional: true
  belongs_to :user
  belongs_to :vaccine, optional: true
  has_one :session, through: :patient_session
  has_one :patient, through: :patient_session
  has_one :campaign, through: :session
  has_one :location, through: :session
  has_one :team, through: :campaign

  scope :administered, -> { where(administered: true) }
  scope :recorded, -> { where.not(recorded_at: nil) }
  scope :draft, -> { rewhere(recorded_at: nil) }

  default_scope { recorded }

  enum :delivery_method,
       %w[intramuscular subcutaneous nasal_spray],
       prefix: true
  enum :delivery_site,
       %w[
         left_arm
         right_arm
         left_arm_upper_position
         left_arm_lower_position
         right_arm_upper_position
         right_arm_lower_position
         left_thigh
         right_thigh
         left_buttock
         right_buttock
         nose
       ],
       prefix: true
  enum :reason,
       %i[
         refused
         not_well
         contraindications
         already_had
         absent_from_school
         absent_from_session
       ]

  encrypts :notes

  validates :notes, length: { maximum: 1000 }

  validates :administered, inclusion: [true, false]
  validates :delivery_site,
            presence: true,
            inclusion: {
              in: delivery_sites.keys
            },
            if: -> { administered && !delivery_site_other }
  validates :delivery_method,
            presence: true,
            inclusion: {
              in: delivery_methods.keys
            },
            if: -> { administered && delivery_site.present? }
  validates :dose_sequence,
            presence: true,
            comparison: {
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: :maximum_dose_sequence
            }

  validate :batch_vaccine_matches_vaccine, if: -> { recorded? && administered }

  on_wizard_step :"delivery-site", exact: true do
    validates :delivery_site,
              presence: true,
              inclusion: {
                in: VaccinationRecord.delivery_sites.keys
              }
    validates :delivery_method,
              presence: true,
              inclusion: {
                in: VaccinationRecord.delivery_methods.keys
              }
  end

  on_wizard_step :reason, exact: true do
    validates :reason, inclusion: { in: VaccinationRecord.reasons.keys }
  end

  on_wizard_step :batch, exact: true do
    validates :batch_id, presence: true
  end

  def location_name
    patient_session.session.location&.name
  end

  def not_administered?
    !administered?
  end

  def recorded?
    recorded_at.present?
  end

  def form_steps
    [
      ("delivery-site" if administered? && delivery_site_other),
      (:batch if administered? && todays_batch.nil?),
      (:reason if not_administered?),
      :confirm
    ].compact
  end

  def dose
    # TODO: this will need to be revisited once it's possible to record half-doses
    # e.g. for the flu programme where a child refuses the second half of the dose
    vaccine.dose * 1
  end

  private

  def maximum_dose_sequence
    vaccine&.maximum_dose_sequence || 1
  end

  def batch_vaccine_matches_vaccine
    return if batch&.vaccine_id == vaccine_id

    errors.add(:batch_id, :incorrect_vaccine, vaccine_brand: vaccine&.brand)
  end
end
