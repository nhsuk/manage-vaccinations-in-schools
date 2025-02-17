# frozen_string_literal: true

class FullNameFormatter
  def self.call(nameable, context:, parts_prefix: nil)
    parts_prefix = "#{parts_prefix}_" if parts_prefix.present?

    given_name =
      nameable.try(:"#{parts_prefix}given_name").presence ||
        nameable.send(:given_name)
    family_name =
      nameable.try(:"#{parts_prefix}family_name").presence ||
        nameable.send(:family_name)

    case context
    when :internal
      "#{family_name.upcase}, #{given_name.upcase_first}"
    when :parents
      "#{given_name.upcase_first} #{family_name.upcase_first}"
    else
      raise "Unknown context: #{context}"
    end
  end
end
