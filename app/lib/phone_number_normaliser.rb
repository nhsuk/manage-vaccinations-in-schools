# frozen_string_literal: true

class PhoneNumberNormaliser
  def call(value)
    Phonelib
      .parse(value)
      .then { it.country == "GB" ? it.national : it.international }
  end
end
