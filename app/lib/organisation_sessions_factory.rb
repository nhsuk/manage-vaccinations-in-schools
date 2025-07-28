# frozen_string_literal: true

class OrganisationSessionsFactory
  def initialize(organisation, academic_year:)
    @organisation = organisation
    @academic_year = academic_year
  end

  def call
    create_missing_sessions!
    destroy_orphaned_sessions!
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :organisation, :academic_year

  def create_missing_sessions!
    ActiveRecord::Base.transaction do
      organisation
        .locations
        .includes(:organisation, :programmes)
        .find_each { LocationSessionsFactory.call(it, academic_year:) }
    end
  end

  def destroy_orphaned_sessions!
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
