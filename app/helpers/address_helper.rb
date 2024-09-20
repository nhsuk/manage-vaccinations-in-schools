# frozen_string_literal: true

module AddressHelper
  def format_address_multi_line(addressable)
    safe_join(addressable.address_parts, tag.br)
  end

  def format_address_single_line(addressable)
    [
      [
        addressable.address_line_1,
        addressable.address_line_2,
        addressable.address_town
      ].compact_blank.join(", "),
      addressable.address_postcode
    ].compact_blank.join(". ")
  end
end
