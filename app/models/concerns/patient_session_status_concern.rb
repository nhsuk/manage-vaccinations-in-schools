# frozen_string_literal: true

module PatientSessionStatusConcern
  extend ActiveSupport::Concern

  included do
    def status(programme:)
      @status_by_programme ||= {}

      @status_by_programme[programme] ||= begin
        outcomes = Outcomes.new(patient_sessions: PatientSession.where(id:))

        if patient.programme_outcome.vaccinated?(programme)
          "vaccinated"
        elsif patient.triage_outcome.delay_vaccination?(programme)
          "delay_vaccination"
        elsif patient.consent_outcome.refused?(programme)
          "consent_refused"
        elsif patient.triage_outcome.do_not_vaccinate?(programme)
          "triaged_do_not_vaccinate"
        elsif outcomes.session.not_vaccinated?(self, programme:)
          "unable_to_vaccinate"
        elsif patient.consent_outcome.given?(programme) &&
              patient.triage_outcome.safe_to_vaccinate?(programme)
          "triaged_ready_to_vaccinate"
        elsif patient.consent_outcome.given?(programme) &&
              patient.triage_outcome.required?(programme)
          "consent_given_triage_needed"
        elsif patient.consent_outcome.given?(programme) &&
              patient.triage_outcome.not_required?(programme)
          "consent_given_triage_not_needed"
        elsif patient.consent_outcome.conflicts?(programme)
          "consent_conflicts"
        else
          "added_to_session"
        end
      end
    end
  end
end
