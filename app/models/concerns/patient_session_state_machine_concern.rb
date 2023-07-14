module PatientSessionStateMachineConcern
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm column: :state do
      state :added_to_session, initial: true
      state :consent_given_triage_not_needed
      state :consent_given_triage_needed
      state :consent_refused
      state :triaged_ready_to_vaccinate
      state :triaged_do_not_vaccinate
      state :triaged_kept_in_triage
      state :unable_to_vaccinate
      state :vaccinated

      event :do_consent do
        transitions from: :added_to_session,
                    to: :consent_given_triage_needed,
                    if: %i[consent_given? triage_needed?]

        transitions from: :added_to_session,
                    to: :consent_given_triage_not_needed,
                    if: %i[consent_given? triage_not_needed?]

        transitions from: :added_to_session,
                    to: :consent_refused,
                    if: :consent_refused?
      end

      event :do_triage do
        transitions from: %i[consent_given_triage_needed triaged_kept_in_triage],
                    to: :triaged_ready_to_vaccinate,
                    if: :triage_ready_to_vaccinate?

        transitions from: %i[consent_given_triage_needed triaged_kept_in_triage],
                    to: :triaged_do_not_vaccinate,
                    if: :triage_do_not_vaccinate?

        transitions from: %i[consent_given_triage_needed triaged_kept_in_triage],
                    to: :triaged_kept_in_triage,
                    if: :triage_keep_in_triage?
      end

      event :do_vaccination do
        transitions from: :consent_given_triage_not_needed,
                    to: :vaccinated,
                    if: :vaccination_administered?

        transitions from: :consent_given_triage_not_needed,
                    to: :unable_to_vaccinate,
                    if: :vaccination_not_administered?

        transitions from: :triaged_ready_to_vaccinate,
                    to: :vaccinated,
                    if: :vaccination_administered?

        transitions from: :triaged_ready_to_vaccinate,
                    to: :unable_to_vaccinate,
                    if: :vaccination_not_administered?
      end
    end

    def consent_given?
      consent_response&.consent_given?
    end

    def consent_refused?
      consent_response&.consent_refused?
    end

    def triage_needed?
      consent_response&.triage_needed?
    end

    def triage_not_needed?
      !consent_response&.triage_needed?
    end

    def triage_ready_to_vaccinate?
      triage&.ready_to_vaccinate?
    end

    def triage_keep_in_triage?
      triage&.needs_follow_up?
    end

    def triage_do_not_vaccinate?
      triage&.do_not_vaccinate?
    end

    def vaccination_administered?
      vaccination_record&.administered?
    end

    def vaccination_not_administered?
      vaccination_record&.administered == false
    end
  end
end
