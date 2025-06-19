# frozen_string_literal: true

class UnscheduledSessionsFactory
  def initialize(academic_year: nil)
    @academic_year = academic_year || Date.current.academic_year
  end

  def call
    Organisation
      .includes(:locations, :programmes, :sessions)
      .find_each { create_for_organisation(it) }
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :academic_year

  def create_for_organisation(organisation)
    create_clinic_sessions!(organisation)
    create_school_sessions!(organisation)
    destroy_orphaned_sessions!(organisation)
  end

  def create_clinic_sessions!(organisation)
    ActiveRecord::Base.transaction do
      organisation.locations.generic_clinic.find_each do |location|
        session =
          organisation.sessions.find_or_initialize_by(academic_year:, location:)
        session.programmes = organisation.programmes
        session.save!
      end
    end
  end

  def create_school_sessions!(organisation)
    schools_and_programmes(organisation).each do |location, programmes|
      eligible_programmes =
        programmes.select { it.year_groups.intersect?(location.year_groups) }

      next if eligible_programmes.empty?

      if organisation
           .sessions
           .has_programmes(eligible_programmes)
           .exists?(academic_year:, location:)
        next
      end

      organisation.sessions.create!(
        academic_year:,
        location:,
        programmes: eligible_programmes
      )
    end
  end

  def schools_and_programmes(organisation)
    schools = organisation.schools
    programmes = ProgrammeGrouper.call(organisation.programmes).values
    schools.to_a.product(programmes.to_a)
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
