# frozen_string_literal: true

class EmailAddressNormaliser
  def call(value)
    value.blank? ? nil : value.downcase.strip
  end
end
