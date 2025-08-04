# frozen_string_literal: true

class GenericClinicFactory
  def initialize(team:)
    @team = team
  end

  def call
    ActiveRecord::Base.transaction do
      location.update!(year_groups:)
      location.create_default_programme_year_groups!(programmes)
      location
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :team

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
    team.locations.find_by(ods_code: team.ods_code, type: :generic_clinic) ||
      Location.create!(
        name: "Community clinic",
        ods_code: team.ods_code,
        subteam:,
        type: :generic_clinic
      )
  end

  def year_groups
    programmes.flat_map(&:default_year_groups).uniq.sort
  end
end
