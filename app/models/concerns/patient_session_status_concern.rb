# frozen_string_literal: true

module PatientSessionStatusConcern
  extend ActiveSupport::Concern

  included do
    def status(programme:)
      @status_by_programme ||= {}

      @status_by_programme[programme] ||= begin
        outcomes = Outcomes.new(patient_sessions: PatientSession.where(id:))

        if outcomes.programme.vaccinated?(patient, programme:)
          "vaccinated"
        elsif outcomes.triage.delay_vaccination?(patient, programme:)
          "delay_vaccination"
        elsif patient.consent_outcome.refused?(programme)
          "consent_refused"
        elsif outcomes.triage.do_not_vaccinate?(patient, programme:)
          "triaged_do_not_vaccinate"
        elsif outcomes.session.not_vaccinated?(self, programme:)
          "unable_to_vaccinate"
        elsif patient.consent_outcome.given?(programme) &&
              outcomes.triage.safe_to_vaccinate?(patient, programme:)
          "triaged_ready_to_vaccinate"
        elsif patient.consent_outcome.given?(programme) &&
              outcomes.triage.required?(patient, programme:)
          "consent_given_triage_needed"
        elsif patient.consent_outcome.given?(programme) &&
              outcomes.triage.not_required?(patient, programme:)
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
