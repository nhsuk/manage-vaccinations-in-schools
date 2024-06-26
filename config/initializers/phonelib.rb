# frozen_string_literal: true

Phonelib.default_country = "GB"

if Settings.allow_dev_phone_numbers
  Phonelib.add_additional_regex :gb, Phonelib::Core::MOBILE, "77009\\d{5}"
end
