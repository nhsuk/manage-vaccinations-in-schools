# frozen_string_literal: true

module IdentityChecksHelper
  def identity_check_label(identity_check)
    if identity_check.confirmed_by_patient?
      "The child"
    else
      "#{identity_check.confirmed_by_other_name} (#{identity_check.confirmed_by_other_relationship})"
    end
  end
end
