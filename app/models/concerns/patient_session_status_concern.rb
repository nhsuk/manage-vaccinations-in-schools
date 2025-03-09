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

      @status_by_programme[
        programme
      ] ||= if patient.programme_outcome.vaccinated?(programme)
        "vaccinated"
      elsif patient.triage_outcome.delay_vaccination?(programme)
        "delay_vaccination"
      elsif session_outcome.not_vaccinated?(programme)
        "unable_to_vaccinate"
      elsif patient.consent_outcome.given?(programme) &&
            patient.triage_outcome.safe_to_vaccinate?(programme)
        "triaged_ready_to_vaccinate"
      elsif patient.triage_outcome.do_not_vaccinate?(programme)
        "triaged_do_not_vaccinate"
      elsif patient.consent_outcome.given?(programme) &&
            patient.triage_outcome.required?(programme)
        "consent_given_triage_needed"
      elsif patient.consent_outcome.given?(programme) &&
            patient.triage_outcome.not_required?(programme)
        "consent_given_triage_not_needed"
      elsif patient.consent_outcome.refused?(programme)
        "consent_refused"
      elsif patient.consent_outcome.conflicts?(programme)
        "consent_conflicts"
      else
        "added_to_session"
      end
    end

    def next_step(programme:)
      if patient.triage_outcome.required?(programme)
        :triage
      elsif patient.consent_given_and_safe_to_vaccinate?(programme:) &&
            register_outcome.attending?
        :vaccinate
      end
    end
  end
end
