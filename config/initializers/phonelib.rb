Phonelib.default_country = "GB"

if Rails.env.in? %w[test development]
  Phonelib.add_additional_regex :gb, Phonelib::Core::MOBILE, "77009\\d{5}"
end
