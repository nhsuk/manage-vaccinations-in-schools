# frozen_string_literal: true

class GenericClinicFactory
  def initialize(organisation:)
    @organisation = organisation
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

  attr_reader :organisation

  delegate :programmes, to: :organisation

  def team
    organisation
      .teams
      .create_with(
        email: organisation.email,
        phone: organisation.phone,
        phone_instructions: organisation.phone_instructions
      )
      .find_or_create_by!(name: organisation.name)
  end

  def location
    organisation.locations.find_by(
      ods_code: organisation.ods_code,
      type: :generic_clinic
    ) ||
      Location.create!(
        name: "Community clinic",
        ods_code: organisation.ods_code,
        team:,
        type: :generic_clinic
      )
  end

  def year_groups
    programmes.flat_map(&:default_year_groups).uniq.sort
  end
end
