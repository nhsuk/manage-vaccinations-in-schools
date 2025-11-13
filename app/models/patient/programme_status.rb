# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_programme_statuses
#
#  id               :bigint           not null, primary key
#  academic_year    :integer          not null
#  date             :date
#  dose_sequence    :integer
#  programme_type   :enum             not null
#  status           :integer          default("not_eligible"), not null
#  vaccine_methods  :integer          is an Array
#  without_gelatine :boolean
#  patient_id       :bigint           not null
#
# Indexes
#
#  idx_on_academic_year_patient_id_3d5bf8d2c8                 (academic_year,patient_id)
#  idx_on_patient_id_academic_year_programme_type_75e0e0c471  (patient_id,academic_year,programme_type) UNIQUE
#  index_patient_programme_statuses_on_patient_id             (patient_id)
#  index_patient_programme_statuses_on_status                 (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#
class Patient::ProgrammeStatus < ApplicationRecord
  include BelongsToProgramme
  include HasVaccineMethods

  belongs_to :patient

  has_many :patient_locations,
           -> { includes(location: :location_programme_year_groups) },
           through: :patient

  has_many :consents,
           -> do
             not_invalidated
               .response_provided
               .includes(:parent, :patient)
               .order(created_at: :desc)
           end,
           through: :patient

  has_many :triages,
           -> { not_invalidated.order(created_at: :desc) },
           through: :patient

  has_many :vaccination_records,
           -> { kept.order(performed_at: :desc) },
           through: :patient

  has_one :attendance_record,
          -> { today },
          through: :patient,
          source: :attendance_records

  GROUPS = %w[
    not_eligible
    needs_consent
    has_refusal
    needs_triage
    due
    cannot_vaccinate
    vaccinated
  ].freeze

  NOT_ELIGIBLE_STATUSES = { "not_eligible" => 0 }.freeze

  NEEDS_CONSENT_STATUSES = {
    "needs_consent_request_not_scheduled" => 10,
    "needs_consent_request_scheduled" => 11,
    "needs_consent_request_failed" => 12,
    "needs_consent_no_response" => 13,
    "needs_consent_follow_up_requested" => 14
  }.freeze

  HAS_REFUSAL_STATUSES = {
    "has_refusal_consent_conflicts" => 20,
    "has_refusal_consent_refused" => 21
  }.freeze

  NEEDS_TRIAGE_STATUSES = { "needs_triage" => 30 }.freeze

  DUE_STATUSES = { "due" => 40 }.freeze

  CANNOT_VACCINATE_STATUSES = {
    "cannot_vaccinate_do_not_vaccinate" => 50,
    "cannot_vaccinate_delay_vaccination" => 51,
    "cannot_vaccinate_absent" => 52,
    "cannot_vaccinate_contraindicated" => 53,
    "cannot_vaccinate_refused" => 53,
    "cannot_vaccinate_unwell" => 54
  }.freeze

  VACCINATED_STATUSES = {
    "vaccinated_fully" => 60,
    "vaccinated_already" => 61
  }.freeze

  enum :status,
       {
         **NOT_ELIGIBLE_STATUSES,
         **NEEDS_CONSENT_STATUSES,
         **HAS_REFUSAL_STATUSES,
         **NEEDS_TRIAGE_STATUSES,
         **DUE_STATUSES,
         **CANNOT_VACCINATE_STATUSES,
         **VACCINATED_STATUSES
       },
       default: :not_eligible,
       validate: true

  scope :needs_consent, -> { where(status: NEEDS_CONSENT_STATUSES.keys) }

  scope :has_refusal, -> { where(status: HAS_REFUSAL_STATUSES.keys) }

  scope :cannot_vaccinate, -> { where(status: CANNOT_VACCINATE_STATUSES.keys) }

  scope :fully_vaccinated, -> { where(status: VACCINATED_STATUSES.keys) }

  def needs_consent? = status.in?(NEEDS_CONSENT_STATUSES.keys)

  def has_refusal? = status.in?(HAS_REFUSAL_STATUSES.keys)

  def cannot_vaccinate? = status.in?(CANNOT_VACCINATE_STATUSES.keys)

  def vaccinated? = status.in?(VACCINATED_STATUSES.keys)

  def group = GROUPS.find { status.starts_with?(it) }

  def assign
    self.date = generator.date
    self.dose_sequence = generator.dose_sequence
    self.status = generator.status
    self.vaccine_methods = generator.vaccine_methods
    self.without_gelatine = generator.without_gelatine
  end

  private

  def generator
    @generator ||=
      StatusGenerator::Programme.new(
        programme:,
        academic_year:,
        patient:,
        patient_locations:,
        consents:,
        triages:,
        attendance_record:,
        vaccination_records:
      )
  end
end
