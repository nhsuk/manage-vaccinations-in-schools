# frozen_string_literal: true

module AddressHelper
  def format_address_multi_line(addressable)
    safe_join(
      [
        addressable.address_line_1,
        addressable.address_line_2,
        addressable.address_town,
        addressable.address_postcode
      ].compact_blank,
      tag.br
    )
  end
end
