# frozen_string_literal: true

module BelongsToLocationAndDate
  extend ActiveSupport::Concern

  included do
    belongs_to :location

    scope :today, -> { where(date: Date.current) }

    scope :for_academic_year,
          ->(academic_year) do
            where(date: academic_year.to_academic_year_date_range)
          end

    scope :for_session,
          ->(session) do
            where(date: session.dates, location_id: session.location_id)
          end
  end

  delegate :today?, to: :date

  delegate :academic_year, to: :date
end
