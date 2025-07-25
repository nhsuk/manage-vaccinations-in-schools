# frozen_string_literal: true

class UnscheduledSessionsFactory
  def initialize(academic_year: nil)
    @academic_year = academic_year || AcademicYear.current
  end

  def call
    Organisation.find_each { handle_organisation!(it) }
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :academic_year

  def handle_organisation!(organisation)
    create_sessions_for_all_programmes!(organisation.locations.generic_clinic)
    create_sessions_per_programme_group!(organisation.locations.school)

    destroy_orphaned_sessions!(organisation)
  end

  def create_sessions_for_all_programmes!(locations)
    locations
      .includes(:organisation, :programmes)
      .find_each do |location|
        organisation = location.organisation
        programmes = location.programmes.reorder(nil)

        if organisation
             .sessions
             .has_programmes(programmes)
             .exists?(academic_year:, location:)
          next
        end

        organisation.sessions.create!(academic_year:, location:, programmes:)
      end
  end

  def create_sessions_per_programme_group!(locations)
    locations
      .includes(:organisation, :programmes)
      .find_each do |location|
        organisation = location.organisation

        ProgrammeGrouper
          .call(location.programmes)
          .each_value do |programmes|
            if organisation
                 .sessions
                 .has_programmes(programmes)
                 .exists?(academic_year:, location:)
              next
            end

            organisation.sessions.create!(
              academic_year:,
              location:,
              programmes:
            )
          end
      end
  end

  def destroy_orphaned_sessions!(organisation)
    ActiveRecord::Base.transaction do
      organisation
        .sessions
        .includes(:location, :session_programmes)
        .unscheduled
        .where(academic_year:)
        .where.not(location: organisation.locations)
        .where
        .missing(:patient_sessions)
        .destroy_all
    end
  end
end
