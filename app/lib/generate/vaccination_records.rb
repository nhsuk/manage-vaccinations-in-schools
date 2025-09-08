# frozen_string_literal: true

class Generate::VaccinationRecords
  def initialize(team:, programme: nil, session: nil, administered: nil)
    @team = team
    @programme = programme || team.programmes.includes(:teams).sample
    @session = session
    @administered = administered
  end

  def call
    create_vaccinations
  end

  def self.call(...) = new(...).call

  private

  attr_reader :config, :team, :programme, :session, :administered

  def create_vaccinations
    attendance_records = []
    vaccination_records = []

    random_patient_locations.each do |patient_location|
      patient = patient_location.patient
      session = patient_location.session

      unless AttendanceRecord.exists?(patient:, location: session.location)
        attendance_records << FactoryBot.build(
          :attendance_record,
          :present,
          patient:,
          session:
        )
      end

      location_name =
        patient_location.location.name if patient_location.session.clinic?

      vaccination_records << FactoryBot.build(
        :vaccination_record,
        :administered,
        patient: patient_location.patient,
        programme:,
        team:,
        performed_by:,
        session: patient_location.session,
        vaccine:,
        batch:,
        location_name:
      )
    end

    AttendanceRecord.import!(attendance_records)
    VaccinationRecord.import!(vaccination_records)

    StatusUpdater.call(patient: vaccination_records.map(&:patient))
  end

  def random_patient_locations
    if administered&.positive?
      patient_locations
        .sample(administered)
        .tap do |selected|
          if selected.size < administered
            info =
              "#{selected.size} (patient_locations) < #{administered} (administered)"
            raise "Not enough patients to generate vaccinations: #{info}"
          end
        end
    else
      patient_locations
    end
  end

  def patient_locations
    (session.presence || team)
      .patient_locations
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
    (@team_users ||= team.users.includes(:teams)).sample
  end
end
