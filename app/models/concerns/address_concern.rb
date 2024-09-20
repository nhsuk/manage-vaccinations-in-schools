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
end
