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
        .map do |programmes|
          organisation.sessions.create!(academic_year:, location:, programmes:)
        end
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

  def grouped_programmes
    @grouped_programmes ||=
      if location.generic_clinic?
        [location.programmes.reorder(nil)]
      else
        ProgrammeGrouper.call(location.programmes).values
      end
  end
end
