# frozen_string_literal: true

module SystmOne
  # TODO: These mappings are valid for Hertforshire, but may not be correct for
  #       other SAIS teams. We'll need to check these are correct with new SAIS
  #       teams.
  DELIVERY_SITES = {
    "Left deltoid" => "left_arm_upper_position",
    "Left anterior forearm" => "left_arm_lower_position",
    "Left lateral thigh" => "left_thigh",
    "Right deltoid" => "right_arm_upper_position",
    "Right anterior forearm" => "right_arm_lower_position",
    "Right lateral thigh" => "right_thigh"
  }.freeze

  GENDER_CODES = { "M" => "male", "F" => "female", "U" => "not_known" }.freeze
end
