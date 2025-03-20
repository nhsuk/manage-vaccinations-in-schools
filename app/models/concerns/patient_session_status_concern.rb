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
        elsif outcomes.consent.refused?(patient, programme:)
          "consent_refused"
        elsif outcomes.triage.do_not_vaccinate?(patient, programme:)
          "triaged_do_not_vaccinate"
        elsif outcomes.session.not_vaccinated?(self, programme:)
          "unable_to_vaccinate"
        elsif outcomes.consent.given?(patient, programme:) &&
              outcomes.triage.safe_to_vaccinate?(patient, programme:)
          "triaged_ready_to_vaccinate"
        elsif outcomes.consent.given?(patient, programme:) &&
              outcomes.triage.required?(patient, programme:)
          "consent_given_triage_needed"
        elsif outcomes.consent.given?(patient, programme:) &&
              outcomes.triage.not_required?(patient, programme:)
          "consent_given_triage_not_needed"
        elsif outcomes.consent.conflicts?(patient, programme:)
          "consent_conflicts"
        else
          "added_to_session"
        end
      end
    end
  end
end
