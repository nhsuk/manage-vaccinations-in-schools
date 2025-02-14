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
    def status
      @status ||=
        if vaccination_administered?
          "vaccinated"
        elsif triage_delay_vaccination? || vaccination_can_be_delayed?
          "delay_vaccination"
        elsif vaccination_not_administered?
          "unable_to_vaccinate"
        elsif triage_keep_in_triage?
          "triaged_kept_in_triage"
        elsif consent_given? && triage_ready_to_vaccinate?
          "triaged_ready_to_vaccinate"
        elsif triage_do_not_vaccinate?
          "triaged_do_not_vaccinate"
        elsif consent_given? && triage_needed?
          "consent_given_triage_needed"
        elsif consent_given? && triage_not_needed?
          "consent_given_triage_not_needed"
        elsif consent_refused?
          "consent_refused"
        elsif consent_conflicts?
          "consent_conflicts"
        else
          "added_to_session"
        end
    end

    PatientSessionStatusConcern.available_statuses.each do |status|
      define_method("#{status}?") { self.status == status }
    end

    def consent_given?
      return false if no_consent?

      programme = programmes.first # TODO: handle multiple programmes

      if (
           self_consents =
             latest_consents(programme:).select(&:via_self_consent?)
         ).present?
        self_consents.all?(&:response_given?)
      else
        latest_consents(programme:).all?(&:response_given?)
      end
    end

    def consent_refused?
      return false if no_consent?

      programme = programmes.first # TODO: handle multiple programmes

      latest_consents(programme:).all?(&:response_refused?)
    end

    def consent_conflicts?
      return false if no_consent?

      programme = programmes.first # TODO: handle multiple programmes

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

    def no_consent?
      programme = programmes.first # TODO: handle multiple programmes
      consents(programme:).empty? ||
        consents(programme:).all? do
          _1.response_not_provided? || _1.invalidated?
        end
    end

    def triage_needed?
      programme = programmes.first # TODO: handle multiple programmes
      latest_consents(programme:).any?(&:triage_needed?)
    end

    def triage_not_needed?
      !triage_needed?
    end

    def triage_ready_to_vaccinate?
      programme = programmes.first # TODO: handle multiple programmes
      latest_triage(programme:)&.ready_to_vaccinate?
    end

    def triage_keep_in_triage?
      programme = programmes.first # TODO: handle multiple programmes
      latest_triage(programme:)&.needs_follow_up?
    end

    def triage_do_not_vaccinate?
      programme = programmes.first # TODO: handle multiple programmes
      latest_triage(programme:)&.do_not_vaccinate?
    end

    def triage_delay_vaccination?
      programme = programmes.first # TODO: handle multiple programmes
      latest_triage(programme:)&.delay_vaccination?
    end

    def vaccination_administered?
      programme = programmes.first # TODO: handle multiple programmes
      vaccination_records(programme:).any?(&:administered?)
    end

    def vaccination_not_administered?
      programme = programmes.first # TODO: handle multiple programmes
      vaccination_records(programme:).any?(&:not_administered?)
    end

    def vaccination_can_be_delayed?
      programme = programmes.first # TODO: handle multiple programmes
      if (vaccination_record = vaccination_records(programme:).last)
        vaccination_record.not_administered? &&
          vaccination_record.retryable_reason?
      end
    end

    def next_step
      if consent_given_triage_needed? || triaged_kept_in_triage?
        :triage
      elsif consent_given_triage_not_needed? || triaged_ready_to_vaccinate? ||
            delay_vaccination?
        :vaccinate
      end
    end
  end
end
