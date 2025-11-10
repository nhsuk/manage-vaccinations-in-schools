# frozen_string_literal: true

class Generate::VaccinationRecords
  def initialize(team:, programme: nil, session: nil, administered: nil)
    @team = team
    @programme = programme || team.programmes.sample
    @session = session
    @administered = administered
  end

  def call = create_vaccinations

  def self.call(...) = new(...).call

  private

  attr_reader :config, :team, :programme, :session, :administered

  def create_vaccinations
    attendance_records = []
    vaccination_records = []

    sessions.each do |session|
      location = session.location

      random_patients_for(session:).each do |patient|
        unless AttendanceRecord.exists?(patient:, location:)
          attendance_records << FactoryBot.build(
            :attendance_record,
            :present,
            patient:,
            session:
          )
        end

        location_name = location.name if session.clinic?

        vaccination_records << FactoryBot.build(
          :vaccination_record,
          :administered,
          patient:,
          programme:,
          team:,
          performed_by:,
          session:,
          vaccine:,
          batch:,
          location_name:
        )
      end
    end

    AttendanceRecord.import!(attendance_records)
    imported_ids = VaccinationRecord.import!(vaccination_records).ids
    SyncPatientTeamJob.perform_later(VaccinationRecord, imported_ids)

    StatusUpdater.call(patient: vaccination_records.map(&:patient))
  end

  def random_patients_for(session:)
    if administered&.positive?
      patients_for(session:)
        .sample(administered)
        .tap do |selected|
          if selected.size < administered
            info =
              "#{selected.size} (patient_locations) < #{administered} (administered)"
            raise "Not enough patients to generate vaccinations: #{info}"
          end
        end
    else
      patients_for(session:)
    end
  end

  def sessions
    (
      @sessions ||=
        session ? [session] : team.sessions.includes(:location, :session_dates)
    )
  end

  def patients_for(session:)
    academic_year = session.academic_year

    session
      .patients
      .includes_statuses
      .appear_in_programmes([programme], academic_year:)
      .has_consent_status("given", programme:, academic_year:)
      .select do
        it.consent_given_and_safe_to_vaccinate?(programme:, academic_year:)
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
