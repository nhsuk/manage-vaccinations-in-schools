# frozen_string_literal: true

module AddressConcern
  extend ActiveSupport::Concern

  included do
    normalizes :address_postcode,
               with: ->(value) do
                 value.nil? ? nil : UKPostcode.parse(value.to_s).to_s
               end
  end

  def address_parts
    [
      address_line_1,
      address_line_2,
      address_town,
      address_postcode
    ].compact_blank
  end

  def has_address?
    address_parts.present?
  end

  def address_changed?
    address_line_1_changed? || address_line_2_changed? ||
      address_town_changed? || address_postcode_changed?
  end
end
