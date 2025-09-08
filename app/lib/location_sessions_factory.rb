# frozen_string_literal: true

class LocationSessionsFactory
  def initialize(location, academic_year:)
    @location = location
    @academic_year = academic_year
  end

  def call
    ActiveRecord::Base.transaction do
      if location.generic_clinic?
        add_patients!(
          session: find_or_create_session!(programmes: location.programmes)
        )
      else
        ProgrammeGrouper
          .call(location.programmes)
          .values
          .reject { |programmes| already_exists?(programmes:) }
          .map { |programmes| create_session!(programmes:) }
          .each { |session| add_patients!(session:) }
      end
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :location, :academic_year

  delegate :team, to: :location

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

  def add_patients!(session:)
    PatientLocation.import!(
      %i[patient_id session_id],
      patient_ids.map { [it, session.id] },
      on_duplicate_key_ignore: true
    )
  end

  def patient_ids
    @patient_ids ||=
      if location.generic_clinic?
        team.patients.where(school: nil).pluck(:id)
      else
        team.patients.where(school: location).pluck(:id)
      end
  end
end
