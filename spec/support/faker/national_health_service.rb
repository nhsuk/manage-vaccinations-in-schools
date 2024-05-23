require "faker"

module Faker
  class NationalHealthService
    class << self
      def test_number
        base_number = rand(999_000_001...999_999_999)
        # If the check digit is equivalent to 10, the number is invalid.
        # See https://en.wikipedia.org/wiki/NHS_number
        base_number -= 1 if check_digit(number: base_number) == 10
        "#{base_number}#{check_digit(number: base_number)}"
          .to_s
          .chars
          .insert(3, " ")
          .insert(7, " ")
          .join
      end
    end
  end
end
