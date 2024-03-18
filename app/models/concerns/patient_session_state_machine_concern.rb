module PatientSessionStateMachineConcern
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm column: :state do
      state :added_to_session, initial: true
      state :consent_given_triage_not_needed
      state :consent_given_triage_needed
      state :consent_refused
      state :consent_conflicts
      state :triaged_ready_to_vaccinate
      state :triaged_do_not_vaccinate
      state :triaged_kept_in_triage
      state :unable_to_vaccinate
      state :unable_to_vaccinate_not_assessed
      state :unable_to_vaccinate_not_gillick_competent
      state :delay_vaccination
      state :vaccinated

      event :do_consent do
        transitions from: %i[
                      added_to_session
                      consent_refused
                      consent_conflicts
                    ],
                    to: :consent_given_triage_needed,
                    if: %i[consent_given? triage_needed?]

        transitions from: %i[
                      added_to_session
                      consent_refused
                      consent_conflicts
                    ],
                    to: :consent_given_triage_not_needed,
                    if: %i[consent_given? triage_not_needed?]

        transitions from: :added_to_session,
                    to: :consent_refused,
                    if: :consent_refused?

        transitions from: :added_to_session,
                    to: :added_to_session,
                    if: :no_consent?

        transitions from: %i[
                      added_to_session
                      consent_given_triage_needed
                      consent_refused
                    ],
                    to: :consent_conflicts,
                    if: :consent_conflicts?
      end

      event :do_gillick_assessment do
        transitions from: :added_to_session,
                    to: :unable_to_vaccinate_not_gillick_competent,
                    if: :not_gillick_competent?
      end

      event :do_triage do
        valid_states_needing_triage = %i[
          consent_given_triage_needed
          consent_given_triage_not_needed
          consent_refused
          triaged_do_not_vaccinate
          triaged_kept_in_triage
          triaged_ready_to_vaccinate
        ]

        transitions from: valid_states_needing_triage,
                    to: :triaged_ready_to_vaccinate,
                    if: :triage_ready_to_vaccinate?

        transitions from: valid_states_needing_triage,
                    to: :triaged_do_not_vaccinate,
                    if: :triage_do_not_vaccinate?

        transitions from: valid_states_needing_triage,
                    to: :triaged_kept_in_triage,
                    if: :triage_keep_in_triage?

        transitions from: valid_states_needing_triage,
                    to: :delay_vaccination,
                    if: :triage_delay_vaccination?
      end

      event :do_vaccination do
        transitions from: :added_to_session,
                    to: :unable_to_vaccinate_not_assessed,
                    if: :no_consent?

        valid_states_for_vaccine_administration = %i[
          consent_given_triage_not_needed
          triaged_ready_to_vaccinate
        ]

        transitions from: valid_states_for_vaccine_administration,
                    to: :vaccinated,
                    if: :vaccination_administered?

        transitions from: valid_states_for_vaccine_administration,
                    to: :unable_to_vaccinate,
                    if: :vaccination_not_administered?

        transitions from: valid_states_for_vaccine_administration,
                    to: :delay_vaccination,
                    if: :vaccination_can_be_delayed?
      end
    end

    def consent_given?
      return false if no_consent?

      latest_consents.all?(&:response_given?)
    end

    def consent_refused?
      return false if no_consent?

      latest_consents.all?(&:response_refused?)
    end

    def consent_conflicts?
      return false if no_consent?

      latest_consents.any?(&:response_refused?) &&
        latest_consents.any?(&:response_given?)
    end

    def no_consent?
      consents.recorded.empty? ||
        consents.recorded.all?(&:response_not_provided?)
    end

    def triage_needed?
      latest_consents.any?(&:triage_needed?)
    end

    def triage_not_needed?
      !triage_needed?
    end

    def triage_ready_to_vaccinate?
      triage.last&.ready_to_vaccinate?
    end

    def triage_keep_in_triage?
      triage.last&.needs_follow_up?
    end

    def triage_do_not_vaccinate?
      triage.last&.do_not_vaccinate?
    end

    def triage_delay_vaccination?
      triage.last&.delay_vaccination?
    end

    def vaccination_administered?
      vaccination_record&.administered?
    end

    def vaccination_not_administered?
      vaccination_record&.administered == false
    end

    def not_gillick_competent?
      !gillick_competent?
    end

    def vaccination_can_be_delayed?
      vaccination_not_administered? &&
        (not_well? || contraindication? || absent_from_session?)
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
