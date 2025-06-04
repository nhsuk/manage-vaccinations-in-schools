# frozen_string_literal: true

module AddressHelper
  def format_address_multi_line(addressable)
    safe_join(addressable.address_parts, tag.br)
  end

  def format_address_single_line(addressable)
    addressable.address_parts.join(", ")
  end

  def format_location_name_and_address_single_line(location)
    [location.name, format_address_single_line(location)].compact_blank.join(
      ", "
    )
  end
end
