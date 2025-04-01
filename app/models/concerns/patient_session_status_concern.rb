# frozen_string_literal: true

module PatientSessionStatusConcern
  extend ActiveSupport::Concern

  def self.available_statuses
    %w[
      added_to_session
      consent_given_triage_not_needed
      consent_given_triage_needed
      consent_refused
      consent_conflicts
      triaged_ready_to_vaccinate
      triaged_do_not_vaccinate
      unable_to_vaccinate
      delay_vaccination
      vaccinated
    ].freeze
  end

  included do
    def status(programme:)
      @status_by_programme ||= {}

      @status_by_programme[programme] ||= if patient.vaccination_status(
           programme:
         ).vaccinated?
        "vaccinated"
      elsif patient.triage_status(programme:).delay_vaccination?
        "delay_vaccination"
      elsif patient.consent_status(programme:).refused?
        "consent_refused"
      elsif patient.triage_status(programme:).do_not_vaccinate?
        "triaged_do_not_vaccinate"
      elsif !session_status(programme:).none_yet? &&
            !session_status(programme:).vaccinated?
        "unable_to_vaccinate"
      elsif patient.consent_status(programme:).given? &&
            patient.triage_status(programme:).safe_to_vaccinate?
        "triaged_ready_to_vaccinate"
      elsif patient.consent_status(programme:).given? &&
            patient.triage_status(programme:).required?
        "consent_given_triage_needed"
      elsif patient.consent_status(programme:).given? &&
            patient.triage_status(programme:).not_required?
        "consent_given_triage_not_needed"
      elsif patient.consent_status(programme:).conflicts?
        "consent_conflicts"
      else
        "added_to_session"
      end
    end
  end
end
