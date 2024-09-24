# frozen_string_literal: true

module AddressConcern
  extend ActiveSupport::Concern

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
