# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id             :bigint           not null, primary key
#  status         :integer          default("not_required"), not null
#  vaccine_method :integer
#  patient_id     :bigint           not null
#  programme_id   :bigint           not null
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
         delay_vaccination: 4
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

    self.vaccine_method = latest_triage&.vaccine_method
  end

  def consent_requires_triage?
    latest_consents.any?(&:requires_triage?)
  end

  def vaccination_history_requires_triage?
    vaccination_records.any? do
      it.programme_id == programme_id && it.administered?
    end && !vaccinated?
  end

  private

  def vaccinated?
    @vaccinated ||=
      VaccinatedCriteria.call(programme:, patient:, vaccination_records:)
  end

  def status_should_be_safe_to_vaccinate?
    return false if vaccinated?
    latest_triage&.ready_to_vaccinate?
  end

  def status_should_be_do_not_vaccinate?
    return false if vaccinated?
    latest_triage&.do_not_vaccinate?
  end

  def status_should_be_delay_vaccination?
    return false if vaccinated?
    latest_triage&.delay_vaccination?
  end

  def status_should_be_required?
    return false if vaccinated?
    return true if latest_triage&.needs_follow_up?

    return false if latest_consents.empty?

    # FIXME: This logic is duplicated from `ConsentStatus`.
    consent_given =
      if (self_consents = latest_consents.select(&:via_self_consent?)).any?
        self_consents.all?(&:response_given?)
      else
        latest_consents.all?(&:response_given?) &&
          latest_consents.map(&:vaccine_methods).inject(&:intersection).present?
      end

    return false unless consent_given

    consent_requires_triage? || vaccination_history_requires_triage?
  end

  def latest_consents
    @latest_consents ||= ConsentGrouper.call(consents, programme_id:)
  end

  def latest_triage
    @latest_triage ||= triages.find { it.programme_id == programme_id }
  end
end
