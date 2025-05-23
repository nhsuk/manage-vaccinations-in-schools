# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                       :bigint           not null, primary key
#  confirmation_sent_at     :datetime
#  delivery_method          :integer
#  delivery_site            :integer
#  discarded_at             :datetime
#  dose_sequence            :integer
#  full_dose                :boolean
#  location_name            :string
#  notes                    :text
#  outcome                  :integer          not null
#  pending_changes          :jsonb            not null
#  performed_at             :datetime         not null
#  performed_by_family_name :string
#  performed_by_given_name  :string
#  performed_ods_code       :string
#  uuid                     :uuid             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  batch_id                 :bigint
#  patient_id               :bigint
#  performed_by_user_id     :bigint
#  programme_id             :bigint           not null
#  session_id               :bigint
#  vaccine_id               :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id              (batch_id)
#  index_vaccination_records_on_discarded_at          (discarded_at)
#  index_vaccination_records_on_patient_id            (patient_id)
#  index_vaccination_records_on_performed_by_user_id  (performed_by_user_id)
#  index_vaccination_records_on_programme_id          (programme_id)
#  index_vaccination_records_on_session_id            (session_id)
#  index_vaccination_records_on_uuid                  (uuid) UNIQUE
#  index_vaccination_records_on_vaccine_id            (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
class VaccinationRecord < ApplicationRecord
  include Discard::Model
  include PendingChangesConcern
  include VaccinationRecordPerformedByConcern

  audited associated_with: :patient

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

  belongs_to :batch, optional: true
  belongs_to :vaccine, optional: true
  belongs_to :performed_by_user, class_name: "User", optional: true
  belongs_to :programme

  has_and_belongs_to_many :dps_exports
  has_and_belongs_to_many :immunisation_imports

  belongs_to :patient
  belongs_to :session, optional: true

  has_one :location, through: :session
  has_one :organisation, through: :session
  has_one :team, through: :session

  scope :recorded_in_service, -> { where.not(session_id: nil) }
  scope :unexported, -> { where.missing(:dps_exports) }

  scope :with_pending_changes,
        -> do
          joins(:patient).where(
            "patients.pending_changes != '{}' OR vaccination_records.pending_changes != '{}'"
          )
        end

  enum :delivery_method,
       { intramuscular: 0, subcutaneous: 1, nasal_spray: 2 },
       prefix: true
  enum :delivery_site,
       {
         left_arm_upper_position: 2,
         left_arm_lower_position: 3,
         right_arm_upper_position: 4,
         right_arm_lower_position: 5,
         left_thigh: 6,
         right_thigh: 7,
         left_buttock: 8,
         right_buttock: 9,
         nose: 10
       },
       prefix: true

  enum :outcome,
       {
         administered: 0,
         refused: 1,
         not_well: 2,
         contraindications: 3,
         already_had: 4,
         absent_from_school: 5,
         absent_from_session: 6
       },
       validate: true

  encrypts :notes

  validates :notes, length: { maximum: 1000 }

  validates :location_name,
            absence: {
              unless: :requires_location_name?
            },
            presence: {
              if: :requires_location_name?
            }

  validates :dose_sequence,
            comparison: {
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: :maximum_dose_sequence,
              allow_nil: true
            }

  validates :performed_at,
            comparison: {
              less_than_or_equal_to: -> { Time.current }
            }

  def not_administered?
    !administered?
  end

  def confirmation_sent?
    confirmation_sent_at != nil
  end

  def recorded_in_service?
    session_id != nil
  end

  def dose_volume_ml
    # TODO: this will need to be revisited once it's possible to record half-doses
    # e.g. for the flu programme where a child refuses the second half of the dose
    vaccine.dose_volume_ml * 1 if vaccine.present?
  end

  def academic_year
    performed_at.to_date.academic_year
  end

  def triage_patient_as_do_not_vaccinate!
    return unless already_had?

    # If an "already had" vaccination record is created, and the patient needs
    # triage, we should record a "do not vaccinate" triage to make sure the
    # patient isn't double vaccinated.

    patient = Patient.includes(:triage_statuses).find(patient_id)
    triage_status = patient.triage_status(programme:)

    return unless triage_status.required? || triage_status.delay_vaccination?

    triage_notes =
      "Recorded as already vaccinated on #{Date.current.to_fs(:long)}"
    triage_notes += ": #{notes}" if notes.present?

    patient.triages.create!(
      programme:,
      organisation:,
      status: :do_not_vaccinate,
      performed_by: performed_by_user,
      notes: triage_notes
    )

    StatusUpdater.call(patient:)
  end

  private

  def requires_location_name?
    session.nil? || location&.generic_clinic?
  end

  delegate :maximum_dose_sequence, to: :programme
end
