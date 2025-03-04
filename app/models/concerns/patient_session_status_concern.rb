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
      triaged_kept_in_triage
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
      elsif triage_delay_vaccination?(programme:) ||
            vaccination_can_be_delayed?(programme:)
        "delay_vaccination"
      elsif vaccination_not_administered?(programme:)
        "unable_to_vaccinate"
      elsif triage_keep_in_triage?(programme:)
        "triaged_kept_in_triage"
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

    def consent_needs_triage?(programme:)
      consent.latest(programme:).any?(&:triage_needed?)
    end

    def triage_needed?(programme:)
      consent_needs_triage?(programme:) ||
        vaccination_partially_administered?(programme:)
    end

    def triage_not_needed?(programme:)
      !triage_needed?(programme:)
    end

    def triage_ready_to_vaccinate?(programme:)
      latest_triage(programme:)&.ready_to_vaccinate?
    end

    def triage_keep_in_triage?(programme:)
      latest_triage(programme:)&.needs_follow_up?
    end

    def triage_do_not_vaccinate?(programme:)
      latest_triage(programme:)&.do_not_vaccinate?
    end

    def triage_delay_vaccination?(programme:)
      latest_triage(programme:)&.delay_vaccination?
    end

    def vaccination_administered?(programme:)
      VaccinatedCriteria.call(
        programme,
        patient:,
        vaccination_records: vaccination_records(programme:)
      )
    end

    def vaccination_partially_administered?(programme:)
      vaccination_records(programme:).any?(&:administered?) &&
        !vaccination_administered?(programme:)
    end

    def vaccination_not_administered?(programme:)
      vaccination_records(programme:).any?(&:not_administered?)
    end

    def vaccination_can_be_delayed?(programme:)
      if (vaccination_record = vaccination_records(programme:).last)
        vaccination_record.not_administered? &&
          vaccination_record.retryable_reason?
      end
    end

    def next_step(programme:)
      if consent_given_triage_needed?(programme:) ||
           triaged_kept_in_triage?(programme:)
        :triage
      elsif consent_given_triage_not_needed?(programme:) ||
            triaged_ready_to_vaccinate?(programme:) ||
            delay_vaccination?(programme:)
        :vaccinate
      end
    end

    # TODO: Remove these once the new session design is complete.

    def section(programme:)
      if added_to_session?(programme:)
        "consents"
      elsif consent_refused?(programme:)
        "consents"
      elsif consent_conflicts?(programme:)
        "consents"
      elsif consent_given_triage_needed?(programme:) ||
            triaged_kept_in_triage?(programme:)
        "triage"
      elsif consent_given_triage_not_needed?(programme:) ||
            triaged_ready_to_vaccinate?(programme:) ||
            delay_vaccination?(programme:)
        "vaccinations"
      elsif triaged_do_not_vaccinate?(programme:) ||
            unable_to_vaccinate?(programme:)
        "vaccinations"
      elsif vaccinated?(programme:)
        "vaccinations"
      end
    end

    def tab(programme:)
      if added_to_session?(programme:)
        "no-consent"
      elsif consent_refused?(programme:)
        "refused"
      elsif consent_conflicts?(programme:)
        "conflicts"
      elsif consent_given_triage_needed?(programme:) ||
            triaged_kept_in_triage?(programme:)
        "needed"
      elsif consent_given_triage_not_needed?(programme:) ||
            triaged_ready_to_vaccinate?(programme:) ||
            delay_vaccination?(programme:)
        "vaccinate"
      elsif triaged_do_not_vaccinate?(programme:) ||
            unable_to_vaccinate?(programme:)
        "could-not"
      elsif vaccinated?(programme:)
        "vaccinated"
      end
    end
  end
end
