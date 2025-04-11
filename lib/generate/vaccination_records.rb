# frozen_string_literal: true

module Generate
  class VaccinationRecords
    attr_reader :config, :organisation, :programme

    def initialize(organisation:, programme: nil, session: nil, administered: 0)
      @organisation = organisation
      @programme = programme || organisation.programmes.sample
      @session = session
      @administered = administered
    end

    def call
      create_vaccination_administered(@administered)
    end

    def self.call(...) = new(...).call

    private

    def patient_sessions
      (@session.presence || organisation)
        .patient_sessions
        .joins(:patient)
        .includes(
          :session,
          patient: [
            :consents,
            :triages,
            :vaccination_records,
            :parents,
            { consents: :parent }
          ]
        )
        .in_programmes([programme])
        .select { it.patient.consent_given_and_safe_to_vaccinate?(programme:) }
    end

    def vaccine
      @vaccine ||= programme.vaccines.includes(:batches).active.first
    end

    def batch
      @batch ||= vaccine.batches.sample
    end

    def random_patient_sessions(count)
      patient_sessions
        .shuffle
        .take(count)
        .tap do
          if it.size < count
            raise "Not enough patients to generate vaccinations"
          end
        end
    end

    def location_name(session)
      session.location.generic_clinic? ? session.location.name : ""
    end

    def user
      @user ||= organisation.users.includes(:organisations).sample
    end

    def create_vaccination_administered(count)
      available_patient_sessions = random_patient_sessions(count)

      available_patient_sessions.each do |patient_session|
        FactoryBot.create(:session_attendance, :present, patient_session:)

        FactoryBot.create(
          :vaccination_record,
          :administered,
          patient: patient_session.patient,
          programme:,
          performed_by: user,
          session: patient_session.session,
          vaccine:,
          batch:,
          location_name: location_name(patient_session.session)
        )
      end
    end
  end
end
