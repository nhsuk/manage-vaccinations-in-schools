# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id           :bigint           not null, primary key
#  status       :integer          default("not_required"), not null
#  patient_id   :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  index_patient_triage_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_triage_statuses_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
class Patient::TriageStatus < ApplicationRecord
  belongs_to :patient
  belongs_to :programme

  has_many :consents,
           -> do
             not_invalidated.response_provided.eager_load(:parent, :patient)
           end,
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
         delay_vaccination: 4
       },
       default: :not_required,
       validate: true

  def assign_status
    self.status =
      if status_should_be_safe_to_vaccinate?
        :safe_to_vaccinate
      elsif status_should_be_do_not_vaccinate?
        :do_not_vaccinate
      elsif status_should_be_delay_vaccination?
        :delay_vaccination
      elsif status_should_be_required?
        :required
      else
        :not_required
      end
  end

  def consent_requires_triage?
    ConsentGrouper.call(consents, programme_id:).any?(&:triage_needed?)
  end

  def vaccination_history_requires_triage?
    vaccination_records.any? do
      it.programme_id == programme_id && it.administered?
    end && !VaccinatedCriteria.call(programme:, patient:, vaccination_records:)
  end

  private

  def status_should_be_safe_to_vaccinate?
    latest_triage&.ready_to_vaccinate?
  end

  def status_should_be_do_not_vaccinate?
    latest_triage&.do_not_vaccinate?
  end

  def status_should_be_delay_vaccination?
    latest_triage&.delay_vaccination?
  end

  def status_should_be_required?
    return true if latest_triage&.needs_follow_up?

    consent_requires_triage? || vaccination_history_requires_triage?
  end

  def latest_triage
    @latest_triage ||= triages.find { it.programme_id == programme_id }
  end
end
