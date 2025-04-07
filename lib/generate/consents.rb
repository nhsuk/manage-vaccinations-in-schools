# frozen_string_literal: true

module Generate
  class Consents
    attr_reader :organisation, :programme

    def initialize(
      organisation:,
      programme: nil,
      session: nil,
      refused: 0,
      given: 0,
      given_needs_triage: 0
    )
      @organisation = organisation
      @programme = programme || organisation.programmes.sample
      @session = session
      @refused = refused
      @given = given
      @given_needs_triage = given_needs_triage
    end

    def call
      create_consent_with_response(:refused, @refused)
      create_consent_with_response(:given, @given)
      create_consent_given_needs_triage(@given_needs_triage)
    end

    def self.call(...) = new(...).call

    private

    def patients
      (@session.presence || organisation)
        .patients
        .includes(:parents, :consents, consents: :parent)
        .in_programmes([programme])
        .select { it.consents.empty? && it.parents.any? }
    end

    def random_patients(count)
      patients
        .shuffle
        .take(count)
        .tap do
          if it.size < count
            raise "Not enough patients without consent and with parents to generate consents"
          end
        end
    end

    def session_for(patient)
      patient
        .sessions
        .eager_load(:location)
        .merge(Location.school)
        .has_programme(programme)
        .sample
    end

    def create_consent_with_response(response, count)
      available_patient_sessions =
        random_patients(count).map { [it, session_for(it)] }

      available_patient_sessions.each do |patient, session|
        consent = FactoryBot.create(:consent, response, patient:, programme:)
        FactoryBot.create(
          :consent_form,
          organisation:,
          programmes: [programme],
          session:,
          consent:,
          response:
        )
      end
    end

    def create_consent_given_needs_triage(count)
      available_patient_sessions =
        random_patients(count).map { [it, session_for(it)] }

      available_patient_sessions.each do |patient, session|
        consent =
          FactoryBot.create(
            :consent,
            :given,
            :needing_triage,
            patient:,
            programme:
          )
        FactoryBot.create(
          :consent_form,
          organisation:,
          programmes: [programme],
          session:,
          consent:,
          response: "given"
        )
      end
    end
  end
end
