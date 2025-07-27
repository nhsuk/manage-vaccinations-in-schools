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
    organisation
      .locations
      .includes(:organisation, :programmes)
      .find_each { LocationSessionsFactory.call(it, academic_year:) }

    destroy_orphaned_sessions!(organisation)
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
