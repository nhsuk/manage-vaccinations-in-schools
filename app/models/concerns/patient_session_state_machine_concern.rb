module PatientSessionStateMachineConcern
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm column: :state do
      state :added_to_session, initial: true
      state :consent_response_received
      state :ready_to_vaccinate
      state :unable_to_vaccinate
      state :vaccinated

      event :received_consent_response do
        transitions from: :added_to_session,
                    to: :consent_response_received,
                    guard: -> {
                      consent_response.consent_given? &&
                        consent_response.triage_needed?
                    }

        transitions from: :added_to_session,
                    to: :ready_to_vaccinate,
                    guard: -> {
                      consent_response.consent_given? &&
                        !consent_response.triage_needed?
                    }

        transitions from: :added_to_session,
                    to: :consent_response_received,
                    guard: -> { consent_response.consent_refused? }
      end

      event :triaged do
        transitions from: :consent_response_received,
                    to: :ready_to_vaccinate,
                    guard: -> { triage.ready_to_vaccinate? }

        transitions from: :consent_response_received,
                    to: :unable_to_vaccinate,
                    guard: -> { triage.do_not_vaccinate? }
      end

      event :did_not_vaccinate do
        transitions from: :ready_to_vaccinate,
                    to: :unable_to_vaccinate,
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
