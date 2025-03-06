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

      @status_by_programme[programme] ||= if outcome.vaccinated?(programme)
        "vaccinated"
      elsif triage.delay_vaccination?(programme)
        "delay_vaccination"
      elsif record.not_vaccinated?(programme)
        "unable_to_vaccinate"
      elsif consent.given?(programme) && triage.safe_to_vaccinate?(programme)
        "triaged_ready_to_vaccinate"
      elsif triage.do_not_vaccinate?(programme)
        "triaged_do_not_vaccinate"
      elsif consent.given?(programme) && triage.required?(programme)
        "consent_given_triage_needed"
      elsif consent.given?(programme) && triage.not_required?(programme)
        "consent_given_triage_not_needed"
      elsif consent.refused?(programme)
        "consent_refused"
      elsif consent.conflicts?(programme)
        "consent_conflicts"
      else
        "added_to_session"
      end
    end

    def next_step(programme:)
      if triage.required?(programme)
        :triage
      elsif ready_for_vaccinator?(programme:)
        :vaccinate
      end
    end
  end
end
