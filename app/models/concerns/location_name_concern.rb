# frozen_string_literal: true

module LocationNameConcern
  extend ActiveSupport::Concern

  included do
    validates :location_name,
              absence: {
                unless: :requires_location_name?
              },
              presence: {
                if: :requires_location_name?
              }
  end

  def requires_location_name?
    location.nil? || location.generic_clinic?
  end
end
