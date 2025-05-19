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
      validate_programme_and_session(programme, session) if programme

      @organisation = organisation
      @programme = programme || organisation.programmes.sample
      @session = session
      @refused = refused
      @given = given
      @given_needs_triage = given_needs_triage
      @updated_patients = []
      @updated_sessions = Set.new
    end

    def call
      create_consent_with_response(:refused, @refused)
      create_consent_with_response(:given, @given)
      create_consent_given_needs_triage(@given_needs_triage)

      StatusUpdater.call(patient: @updated_patients, session: @updated_sessions)
    end

    def self.call(...) = new(...).call

    private

    def patients
      @patients ||=
        begin
          sessions =
            if @session
              [@session]
            else
              organisation
                .sessions
                .eager_load(:location)
                .merge(Location.school)
                .has_programme(programme)
            end

          sessions.flat_map do |session|
            session
              .patients
              .includes(:parents, :school, :consents, consents: :parent)
              .select { it.consents.empty? && it.parents.any? }
          end
        end
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
      @session ||
        patient
          .sessions
          .eager_load(:location)
          .merge(Location.school)
          .has_programme(programme)
          .sample
    end

    def create_consents_with_responses(response, count)
      available_patient_sessions =
        random_patients(count).map { [it, session_for(it)] }

      consents =
        available_patient_sessions.map do |patient, session|
          school = session.location.school? ? session.location : patient.school

          @updated_patients << patient
          @updated_sessions << session

          FactoryBot.build(
            :consent,
            patient:,
            programme:,
            consent_form:
              FactoryBot.build(
                :consent_form,
                organisation:,
                programmes: [programme],
                session:,
                school:,
                response:
              )
          )
        end
      Consent.import(consents, recursive: true)
    end

    def create_consent_given_needs_triage(count)
      available_patient_sessions =
        random_patients(count).map { [it, session_for(it)] }

      consents =
        available_patient_sessions.map do |patient, session|
          school = session.location.school? ? session.location : patient.school

          @updated_patients << patient
          @updated_sessions << session

          FactoryBot.build(
            :consent,
            :given,
            :needing_triage,
            patient:,
            programme:,
            consent_form:
              FactoryBot.build(
                :consent_form,
                organisation:,
                programmes: [programme],
                session:,
                school:,
                response: "given"
              )
          )
        end

      Consent.import(consents, recursive: true)
    end

    def validate_programme_and_session(programme, session)
      if session
        if session.programmes.exclude?(programme)
          raise "Session does not support programme #{programme.type}"
        end
      elsif programme.sessions.none? { it.location.school? }
        raise "Programme #{programme.type} does not have a school session"
      end
    end
  end
end
