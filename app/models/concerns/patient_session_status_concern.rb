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

      @status_by_programme[programme] ||= if vaccination_administered?(
           programme:
         )
        "vaccinated"
      elsif triage_delay_vaccination?(programme:)
        "delay_vaccination"
      elsif vaccination_not_administered?(programme:)
        "unable_to_vaccinate"
      elsif consent_given?(programme:) && triage_ready_to_vaccinate?(programme:)
        "triaged_ready_to_vaccinate"
      elsif triage_do_not_vaccinate?(programme:)
        "triaged_do_not_vaccinate"
      elsif consent_given?(programme:) && triage_needed?(programme:)
        "consent_given_triage_needed"
      elsif consent_given?(programme:) && triage_not_needed?(programme:)
        "consent_given_triage_not_needed"
      elsif consent_refused?(programme:)
        "consent_refused"
      elsif consent_conflicts?(programme:)
        "consent_conflicts"
      else
        "added_to_session"
      end
    end

    PatientSessionStatusConcern.available_statuses.each do |status|
      define_method("#{status}?") do |programme:|
        self.status(programme:) == status
      end
    end

    def consent_given?(programme:)
      consent.status[programme] == PatientSession::Consent::GIVEN
    end

    def consent_refused?(programme:)
      consent.status[programme] == PatientSession::Consent::REFUSED
    end

    def consent_conflicts?(programme:)
      consent.status[programme] == PatientSession::Consent::CONFLICTS
    end

    def no_consent?(programme:)
      consent.status[programme] == PatientSession::Consent::NONE
    end

    def triage_needed?(programme:)
      triage.status[programme] == PatientSession::Triage::REQUIRED
    end

    def triage_not_needed?(programme:)
      triage.status[programme] == PatientSession::Triage::NOT_REQUIRED
    end

    def triage_ready_to_vaccinate?(programme:)
      triage.status[programme] == PatientSession::Triage::SAFE_TO_VACCINATE
    end

    def triage_do_not_vaccinate?(programme:)
      triage.status[programme] == PatientSession::Triage::DO_NOT_VACCINATE
    end

    def triage_delay_vaccination?(programme:)
      triage.status[programme] == PatientSession::Triage::DELAY_VACCINATION
    end

    def vaccination_administered?(programme:)
      outcome.status[programme] == PatientSession::Outcome::VACCINATED
    end

    def vaccination_not_administered?(programme:)
      outcome.all(programme:).any?(&:not_administered?)
    end

    def next_step(programme:)
      if triage.status[programme] == PatientSession::Triage::REQUIRED
        :triage
      elsif ready_for_vaccinator?(programme:)
        :vaccinate
      end
    end
  end
end
