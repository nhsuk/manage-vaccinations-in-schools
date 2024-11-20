# frozen_string_literal: true

module LocationNameConcern
  extend ActiveSupport::Concern

  included do
    validates :location_name, absence: true, unless: :requires_location_name?
    validates :location_name, presence: true, if: :requires_location_name?
  end

  def requires_location_name?
    location&.generic_clinic?
  end
end
