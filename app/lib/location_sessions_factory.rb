# frozen_string_literal: true

class LocationSessionsFactory
  def initialize(location, academic_year:)
    @location = location
    @academic_year = academic_year
  end

  def call
    ActiveRecord::Base.transaction do
      grouped_programmes
        .reject { |programmes| already_exists?(programmes:) }
        .map { |programmes| create_session!(programmes:) }
        .each { |session| add_patients!(session:) }
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :location, :academic_year

  delegate :organisation, to: :location

  def already_exists?(programmes:)
    organisation
      .sessions
      .has_programmes(programmes)
      .exists?(academic_year:, location:)
  end

  def create_session!(programmes:)
    organisation.sessions.create!(academic_year:, location:, programmes:)
  end

  def add_patients!(session:)
    PatientSession.import!(
      %i[patient_id session_id],
      patient_ids.map { [it, session.id] },
      on_duplicate_key_ignore: true
    )
  end

  def grouped_programmes
    @grouped_programmes ||=
      if location.generic_clinic?
        [location.programmes.reorder(nil)]
      else
        ProgrammeGrouper.call(location.programmes).values
      end
  end

  def patient_ids
    @patient_ids ||=
      if location.generic_clinic?
        organisation.patients.pluck(:id)
      else
        organisation.patients.where(school: location).pluck(:id)
      end
  end
end
