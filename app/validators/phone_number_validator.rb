class PhoneNumberValidator < ActiveModel::EachValidator
  UK_PREFIX = "44".freeze
  ALL_WHITESPACE = " \t\r\n".freeze

  def validate_each(record, attribute, value)
    number = value.to_s.tr("#{ALL_WHITESPACE}()\\-+", "")
    unless number =~ /\A\d+\z/
      record.errors.add(attribute, :invalid)
      return
    end

    number = number.sub(/^0+/, "").delete_prefix(UK_PREFIX).delete_prefix("0")

    unless number.start_with?("7")
      record.errors.add(attribute, :invalid)
      return
    end

    if number.length > 10
      record.errors.add(attribute, :invalid)
      return
    end

    if number.length < 10
      record.errors.add(attribute, :invalid)
      return # rubocop:disable Style/RedundantReturn
    end
  end

  private

  def normalise_phone_number(number)
  end
end
