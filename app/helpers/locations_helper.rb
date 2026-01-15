# frozen_string_literal: true

module LocationsHelper
  def location_display_name(location, show_postcode: false, show_urn: false)
    return location.name unless show_postcode || show_urn

    identifier =
      (
        if show_postcode
          location.address_postcode
        else
          "URN: #{location.urn_and_site}"
        end
      )
    "#{location.name} (#{identifier})"
  end
end
