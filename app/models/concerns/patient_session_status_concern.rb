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

      if latest_self_consents.present?
        latest_self_consents.all?(&:response_given?)
      else
        latest_consents.all?(&:response_given?)
      end
    end

    def consent_refused?
      return false if no_consent?

      latest_consents.all?(&:response_refused?)
    end

    def consent_conflicts?
      return false if no_consent?

      if latest_self_consents.present?
        latest_self_consents.any?(&:response_refused?) &&
          latest_self_consents.any?(&:response_given?)
      else
        latest_consents.any?(&:response_refused?) &&
          latest_consents.any?(&:response_given?)
      end
    end

    def no_consent?
      consents.empty? ||
        consents.all? { _1.response_not_provided? || _1.invalidated? }
    end

    def triage_needed?
      latest_consents.any?(&:triage_needed?)
    end

    def triage_not_needed?
      !triage_needed?
    end

    def triage_ready_to_vaccinate?
      latest_triage&.ready_to_vaccinate?
    end

    def triage_keep_in_triage?
      latest_triage&.needs_follow_up?
    end

    def triage_do_not_vaccinate?
      latest_triage&.do_not_vaccinate?
    end

    def triage_delay_vaccination?
      latest_triage&.delay_vaccination?
    end

    def vaccination_administered?
      vaccination_records.any?(&:administered?)
    end

    def vaccination_not_administered?
      vaccination_records.any?(&:not_administered?)
    end

    def vaccination_can_be_delayed?
      if (vaccination_record = vaccination_records.last)
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
