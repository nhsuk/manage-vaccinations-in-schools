# frozen_string_literal: true

module AddressHelper
  def format_address_multi_line(addressable)
    safe_join(addressable.address_parts, tag.br)
  end

  def format_address_single_line(addressable)
    addressable.address_parts.join(", ")
  end
end
