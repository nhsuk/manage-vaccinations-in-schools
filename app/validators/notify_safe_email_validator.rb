class NotifySafeEmailValidator < ActiveModel::EachValidator
  VALID_LOCAL_CHARS = 'a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-'.freeze
  EMAIL_REGEX_PATTERN = /^[#{VALID_LOCAL_CHARS}]+@([^.@][^@\s]+)$/
  HOSTNAME_PART = /^(xn|[a-z0-9]+)(-?-[a-z0-9]+)*$/i
  TLD_PART = /^([a-z]{2,63}|xn--([a-z0-9]+-)*[a-z0-9]+)$/i

  def validate_each(record, attribute, value)
    match = EMAIL_REGEX_PATTERN.match(value)

    if !match || value.length > 320 || value.include?("..")
      record.errors.add(attribute, :invalid)
      return
    end

    hostname = match[1]

    parts = hostname.split(".")

    if hostname.length > 253 || parts.length < 2
      record.errors.add(attribute, :invalid)
      return
    end

    unless parts.all? { |part| HOSTNAME_PART.match?(part) }
      record.errors.add(attribute, :invalid)
      return
    end

    unless TLD_PART.match?(parts.last)
      record.errors.add(attribute, :invalid)
      return # rubocop:disable Style/RedundantReturn
    end
  end
end
