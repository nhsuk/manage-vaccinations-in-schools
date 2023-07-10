module PatientSessionStateMachineConcern
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm column: :state do
      state :awaiting_consent_response, initial: true
      state :awaiting_triage
      state :ready_to_vaccinate
      state :not_vaccinated
      state :vaccinated

      event :received_consent_response do
        transitions from: :awaiting_consent_response,
                    to: :awaiting_triage,
                    guard: -> {
                      consent_response.consent_given? &&
                        consent_response.triage_needed?
                    }

        transitions from: :awaiting_consent_response,
                    to: :ready_to_vaccinate,
                    guard: -> {
                      consent_response.consent_given? &&
                        !consent_response.triage_needed?
                    }

        transitions from: :awaiting_consent_response,
                    to: :awaiting_triage,
                    guard: -> { consent_response.consent_refused? }
      end

      event :triaged do
        transitions from: :awaiting_triage,
                    to: :ready_to_vaccinate,
                    guard: -> { triage.ready_to_vaccinate? }

        transitions from: :awaiting_triage,
                    to: :not_vaccinated,
                    guard: -> { triage.do_not_vaccinate? }
      end

      event :did_not_vaccinate do
        transitions from: :ready_to_vaccinate,
                    to: :not_vaccinated,
                    guard: -> { vaccination_record.administered == false }
      end

      event :vaccinate do
        transitions from: :ready_to_vaccinate,
                    to: :vaccinated,
                    guard: -> { vaccination_record.administered? }
      end
    end
  end
end
