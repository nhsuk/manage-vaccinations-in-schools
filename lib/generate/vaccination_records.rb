# frozen_string_literal: true

module Generate
  class VaccinationRecords
    attr_reader :config, :organisation, :programme, :session, :administered

    def initialize(
      organisation:,
      programme: nil,
      session: nil,
      administered: nil
    )
      @organisation = organisation
      @programme = programme || organisation.programmes.sample
      @session = session
      @administered = administered
    end

    def call
      create_vaccinations
    end

    def self.call(...) = new(...).call

    private

    def create_vaccinations
      random_patient_sessions.each do |patient_session|
        patient_session_id = patient_session.id
        session_date_ids = patient_session.session.session_dates.pluck(:id)

        unless SessionAttendance.exists?(
                 patient_session_id:,
                 session_date_id: session_date_ids
               )
          FactoryBot.create(:session_attendance, :present, patient_session:)
        end

        FactoryBot.create(
          :vaccination_record,
          :administered,
          patient: patient_session.patient,
          programme:,
          performed_by:,
          session:,
          vaccine:,
          batch:,
          location_name: patient_session.location.name
        )
      end

      StatusUpdater.call(patient: patient_sessions.map(&:patient))
    end

    def random_patient_sessions
      if administered&.positive?
        patient_sessions
          .shuffle
          .take(administered)
          .tap do |selected|
            if selected.size < administered
              info =
                "#{selected.size} (patient_sessions) < #{administered} (administered)"
              raise "Not enough patients to generate vaccinations: #{info}"
            end
          end
      else
        patient_sessions
      end
    end

    def patient_sessions
      (session.presence || organisation)
        .patient_sessions
        .joins(:patient)
        .includes(
          :session,
          :location,
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
      programme.vaccines.includes(:batches).active.first
    end

    def batch
      vaccine.batches.sample
    end

    def performed_by
      organisation.users.includes(:organisations).sample
    end
  end
end
