# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                 :bigint           not null, primary key
#  administered       :boolean
#  delivery_method    :integer
#  delivery_site      :integer
#  notes              :text
#  reason             :integer
#  recorded_at        :datetime
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

  # HACK: this code will need to be revisited in future as it only really works for HPV, where we only have one vaccine
  # It is likely to fail for the Doubles programme as that has 2 vaccines
  # It is also likely to fail for the flu programme for the SAIS teams that offer both nasal and injectable vaccines
  after_initialize do
    if patient_session.present?
      self.vaccine_id ||= patient_session.session.campaign.vaccines.first&.id
    end
  end

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
    validates :reason,
              inclusion: {
                in: VaccinationRecord.reasons.keys
              }
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
      ("delivery-site" if administered? && delivery_site.nil?),
      (:batch if administered? && batch_id.nil?),
      (:reason if not_administered?),
      :confirm
    ].compact
  end

  private

  def batch_vaccine_matches_vaccine
    return if batch&.vaccine_id == vaccine_id

    errors.add(:batch_id, :incorrect_vaccine, vaccine_brand: vaccine&.brand)
  end
end
