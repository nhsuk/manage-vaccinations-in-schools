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

  class NotEnoughAvailablePatients < StandardError
  end

  class SessionHasNoDates < StandardError
  end

  class NoSessionsWithDates < StandardError
  end

  class NoSessionsWithPatients < StandardError
  end

  private

  attr_reader :config, :team, :programme, :session, :administered

  def create_vaccinations
    attendances = []
    vaccinations = []

    check_sessions_have_enough_patients

    each_random_patient_ready_for_vaccination(
      administered
    ) do |session, patient|
      attendance, vaccination =
        create_administered_vaccination(session, patient)

      attendances << attendance if attendance.present?
      vaccinations << vaccination
    end

    AttendanceRecord.import!(attendances)
    VaccinationRecord.import!(vaccinations)

    patients = vaccinations.map(&:patient)

    PatientTeamUpdater.call(
      patient_scope: Patient.where(id: patients.map(&:id))
    )

    StatusUpdater.call(patient: patients)
  end

  def check_sessions_have_enough_patients
    available_patients = sessions.sum { patients_for(session: it).count }
    if available_patients < administered
      info =
        "#{available_patients} (available patients) < #{administered} (administered)"
      raise NotEnoughAvailablePatients, info
    end
  end

  def each_random_patient_ready_for_vaccination(count)
    count.times do
      session = sessions.sample
      patients = patients_for(session:)

      patient = patients.sample

      yield session, patient

      patients.delete(patient)
      sessions.delete(session) if patients.empty?
    end
  end

  def create_administered_vaccination(session, patient)
    location = session.location

    attendance = nil

    unless AttendanceRecord.exists?(patient:, location:)
      attendance =
        FactoryBot.build(:attendance_record, :present, patient:, session:)
    end

    location_name = location.name if session.clinic?

    vaccination =
      FactoryBot.build(
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

    [attendance, vaccination]
  end

  def sessions
    @sessions ||=
      if session
        raise SessionHasNoDates, session.id if session.dates.empty?
        [session]
      else
        team
          .sessions
          .where.not(dates: [])
          .tap { raise NoSessionsWithDates if it.empty? }
          .includes(:location, :session_programme_year_groups, :team_location)
          .select { patients_for(session: it).any? }
          .tap { raise NoSessionsWithPatients if it.empty? }
      end
  end

  def patients_for(session:)
    @patients_for ||= {}
    return @patients_for[session.id] if @patients_for.key?(session.id)

    academic_year = session.academic_year

    @patients_for[session.id] = session
      .patients
      .includes_statuses
      .appear_in_programmes([programme], academic_year:)
      .has_programme_status("due", programme:, academic_year:)
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
