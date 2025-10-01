# frozen_string_literal: true

class GenericClinicFactory
  def initialize(team:, academic_year:)
    @team = team
    @academic_year = academic_year
  end

  def call
    ActiveRecord::Base.transaction do
      location.update!(gias_year_groups: year_groups)
      location.import_year_groups!(
        year_groups,
        academic_year:,
        source: "generic_clinic_factory"
      )
      location.create_default_programme_year_groups!(programmes, academic_year:)
      location
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :team, :academic_year

  delegate :programmes, to: :team

  def subteam
    team
      .subteams
      .create_with(
        email: team.email,
        phone: team.phone,
        phone_instructions: team.phone_instructions
      )
      .find_or_create_by!(name: team.name)
  end

  def location
    team.locations.find_by(type: :generic_clinic) ||
      Location.create!(
        name: "Community clinic",
        subteam:,
        type: :generic_clinic
      )
  end

  def year_groups = Location::YearGroup::VALUE_RANGE.to_a
end
