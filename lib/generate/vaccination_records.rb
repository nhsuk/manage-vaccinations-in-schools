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
      @programme =
        programme || organisation.programmes.includes(:organisations).sample
      @session = session
      @administered = administered
    end

    def call
      create_vaccinations
    end

    def self.call(...) = new(...).call

    private

    def create_vaccinations
      session_attendances = []
      vaccination_records = []

      random_patient_sessions.each do |patient_session|
        patient_session_id = patient_session.id
        session_date_ids = patient_session.session.session_dates.pluck(:id)

        unless SessionAttendance.exists?(
                 patient_session_id:,
                 session_date_id: session_date_ids
               )
          session_attendances << FactoryBot.build(
            :session_attendance,
            :present,
            patient_session:
          )
        end

        location_name =
          patient_session.location.name if patient_session.session.clinic?

        vaccination_records << FactoryBot.build(
          :vaccination_record,
          :administered,
          patient: patient_session.patient,
          programme:,
          organisation:,
          performed_by:,
          session: patient_session.session,
          vaccine:,
          batch:,
          location_name:
        )
      end

      SessionAttendance.import!(session_attendances)
      VaccinationRecord.import!(vaccination_records)

      StatusUpdater.call(patient: vaccination_records.map(&:patient))
    end

    def random_patient_sessions
      if administered&.positive?
        patient_sessions
          .sample(administered)
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
          session: :session_dates,
          patient: %i[consent_statuses vaccination_statuses triage_statuses]
        )
        .appear_in_programmes([programme])
        .has_consent_status("given", programme:)
        .select do
          it.patient.consent_given_and_safe_to_vaccinate?(
            programme:,
            academic_year: it.session.academic_year
          )
        end
    end

    def vaccine
      (@vaccines ||= programme.vaccines.includes(:batches).active).first
    end

    def batch
      (@batches ||= vaccine.batches).sample
    end

    def performed_by
      (
        @organisation_users ||= organisation.users.includes(:organisations)
      ).sample
    end
  end
end
