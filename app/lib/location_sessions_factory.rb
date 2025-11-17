# frozen_string_literal: true

class LocationSessionsFactory
  def initialize(location, academic_year:, sync_patient_teams_now: false)
    @location = location
    @academic_year = academic_year
    @sync_patient_teams_now = sync_patient_teams_now
  end

  def call
    imported_patient_location_ids =
      ActiveRecord::Base.transaction do
        if location.generic_clinic?
          find_or_create_session!(programmes: location.programmes)
        else
          ProgrammeGrouper
            .call(location.programmes)
            .values
            .reject { |programmes| catch_up_only?(programmes:) }
            .reject { |programmes| already_exists?(programmes:) }
            .map { |programmes| create_session!(programmes:) }
        end

        add_patients!
      end
    if sync_patient_teams_now
      SyncPatientTeamJob.perform_now(
        PatientLocation,
        imported_patient_location_ids
      )
    else
      SyncPatientTeamJob.perform_later(
        PatientLocation,
        imported_patient_location_ids
      )
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :location, :academic_year, :sync_patient_teams_now

  delegate :team, to: :location

  def catch_up_only?(programmes:)
    programmes.all?(&:catch_up_only?)
  end

  def already_exists?(programmes:)
    team.sessions.has_programmes(programmes).exists?(academic_year:, location:)
  end

  def create_session!(programmes:)
    team.sessions.create!(academic_year:, location:, programmes:)
  end

  def find_or_create_session!(programmes:)
    team
      .sessions
      .create_with(programmes:)
      .find_or_create_by!(academic_year:, location:)
      .tap do |session|
        programmes.each do |programme|
          unless programme.in?(session.programmes)
            session.programmes << programme
          end
        end
      end
  end

  def add_patients!
    PatientLocation.import!(
      %i[patient_id location_id academic_year],
      patient_ids.map { [it, location.id, academic_year] },
      on_duplicate_key_ignore: true
    ).ids
  end

  def patient_ids
    @patient_ids ||=
      if location.generic_clinic?
        patients_in_sessions.where(school: nil).pluck(:id)
      else
        patients_in_sessions.where(school: location).pluck(:id)
      end
  end

  def patients_in_sessions
    Patient.joins_sessions.where(sessions: { team_id: team.id })
  end
end
