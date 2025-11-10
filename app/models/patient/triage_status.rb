# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id               :bigint           not null, primary key
#  academic_year    :integer          not null
#  programme_type   :enum             not null
#  status           :integer          default("not_required"), not null
#  vaccine_method   :integer
#  without_gelatine :boolean
#  patient_id       :bigint           not null
#  programme_id     :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_academic_year_6cf32349df        (patient_id,programme_id,academic_year) UNIQUE
#  index_patient_triage_statuses_on_academic_year_and_patient_id  (academic_year,patient_id)
#  index_patient_triage_statuses_on_status                        (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::TriageStatus < ApplicationRecord
  include BelongsToProgramme

  belongs_to :patient

  has_many :consents,
           -> { not_invalidated.response_provided.includes(:parent, :patient) },
           through: :patient

  has_many :triages,
           -> { not_invalidated.order(created_at: :desc) },
           through: :patient

  has_many :vaccination_records,
           -> { kept.order(performed_at: :desc) },
           through: :patient

  enum :status,
       {
         not_required: 0,
         required: 1,
         safe_to_vaccinate: 2,
         do_not_vaccinate: 3,
         delay_vaccination: 4,
         invite_to_clinic: 5
       },
       default: :not_required,
       validate: true

  enum :vaccine_method,
       { injection: 0, nasal: 1 },
       prefix: true,
       validate: {
         if: :safe_to_vaccinate?
       }

  def assign_status
    self.status = generator.status
    self.vaccine_method = generator.vaccine_method
    self.without_gelatine = generator.without_gelatine
  end

  delegate :consent_requires_triage?,
           :vaccination_history_requires_triage?,
           to: :generator

  private

  def generator
    @generator ||=
      StatusGenerator::Triage.new(
        programme:,
        academic_year:,
        patient:,
        consents:,
        triages:,
        vaccination_records:
      )
  end
end
