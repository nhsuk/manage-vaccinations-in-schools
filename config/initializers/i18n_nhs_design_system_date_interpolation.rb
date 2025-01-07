# frozen_string_literal: true

# This custom interpolation is used to format interpolated dates in error messages
# so they align to the NHS design system.
module I18n
  module NHSDesignSystemDateInterpolation
    def interpolate(locale, string, values = {})
      values = values.dup # Duplicate to avoid mutating the original hash

      # Check if :count is a Date
      values[:count] = values[:count].to_fs(:long) if values[:count].is_a?(Date)

      # Convert any ISO-8859-1 values
      values[:value] = values[:value].encode("UTF-8") if values[:value].is_a?(
        String
      )

      # Call the original interpolate method with modified values
      super(locale, string, values)
    end
  end

  # Include the custom interpolation module in the backend
  Backend::Simple.include(NHSDesignSystemDateInterpolation)
end
