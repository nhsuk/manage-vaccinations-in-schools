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
      return false if no_consent?(programme:)

      if (
           self_consents =
             latest_consents(programme:).select(&:via_self_consent?)
         ).present?
        self_consents.all?(&:response_given?)
      else
        latest_consents(programme:).all?(&:response_given?)
      end
    end

    def consent_refused?(programme:)
      return false if no_consent?(programme:)

      latest_consents(programme:).all?(&:response_refused?)
    end

    def consent_conflicts?(programme:)
      return false if no_consent?(programme:)

      if (
           self_consents =
             latest_consents(programme:).select(&:via_self_consent?)
         ).present?
        self_consents.any?(&:response_refused?) &&
          self_consents.any?(&:response_given?)
      else
        latest_consents(programme:).any?(&:response_refused?) &&
          latest_consents(programme:).any?(&:response_given?)
      end
    end

    def no_consent?(programme:)
      consents(programme:).empty? ||
        consents(programme:).all? do
          _1.response_not_provided? || _1.invalidated?
        end
    end

    def triage_needed?(programme:)
      latest_consents(programme:).any?(&:triage_needed?)
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
      # TODO: This logic doesn't work for vaccinations that require multiple doses.
      vaccination_records(programme:).any?(&:administered?)
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
  end
end
