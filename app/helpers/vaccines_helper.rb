# frozen_string_literal: true

module VaccinesHelper
  def vaccine_heading(vaccine)
    "#{vaccine.brand} (#{vaccine.programme.name})"
  end
end
