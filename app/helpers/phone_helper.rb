# frozen_string_literal: true

module PhoneHelper
  def format_phone_with_instructions(entity)
    return entity.phone if entity.phone_instructions.blank?

    "#{entity.phone} (#{entity.phone_instructions})"
  end
end
