# frozen_string_literal: true

require "faker"
require "concurrent"

class PIIAnonymizer
  module FakeDataGenerators
    # Custom exceptions for data generation
    class GenerationError < StandardError
    end
    class UniqueConstraintError < StandardError
    end

    # Base class for all fake data generators with common functionality
    # Uses independent thread approach - no shared caches, relies on retry mechanisms
    class BaseGenerator
      class << self
        # Validate that a generated value meets field requirements
        def validate_value(value, requirements = {})
          return false if value.nil? && !requirements[:nullable]
          if value.present? && requirements[:max_length] &&
               value.length > requirements[:max_length]
            return false
          end
          if value.present? && requirements[:min_length] &&
               value.length < requirements[:min_length]
            return false
          end
          if requirements[:format] && value.respond_to?(:match?) &&
               !value.match?(requirements[:format])
            return false
          end

          true
        end

        # Ensure UK locale for Faker to generate appropriate data
        def with_uk_locale(&block)
          original_locale = Faker::Config.locale
          Faker::Config.locale = "en-GB"
          result = block.call
          Faker::Config.locale = original_locale
          result
        rescue StandardError => e
          Faker::Config.locale = original_locale
          raise e
        end

        # Generate high-entropy random values to minimize collision probability
        def high_entropy_random(length = 8)
          SecureRandom.alphanumeric(length)
        end

        # Generate random number with large space to minimize collisions
        def large_random_number(digits = 10)
          # Generate number with specified digits, ensuring it doesn't start with 0
          min = 10**(digits - 1)
          max = (10**digits) - 1
          rand(min..max)
        end
      end
    end

    # Generator classes using independent thread approach with large random spaces
    class NameGenerator < BaseGenerator
      class << self
        def first_name
          # Use realistic UK first names - no uniqueness required
          base_names = %w[
            James
            John
            Robert
            Michael
            William
            David
            Richard
            Charles
            Joseph
            Thomas
            Christopher
            Daniel
            Paul
            Mark
            Donald
            Steven
            Andrew
            Kenneth
            Paul
            Joshua
            Mary
            Patricia
            Jennifer
            Linda
            Elizabeth
            Barbara
            Susan
            Jessica
            Sarah
            Karen
            Nancy
            Lisa
            Betty
            Helen
            Sandra
            Donna
            Carol
            Ruth
            Sharon
            Michelle
            Laura
            Oliver
            Harry
            George
            Noah
            Jack
            Jacob
            Logan
            Mason
            Ethan
            Alexander
            Lucas
            Emma
            Olivia
            Ava
            Isabella
            Sophia
            Charlotte
            Mia
            Amelia
            Harper
            Evelyn
          ]
          base_names.sample
        end

        def last_name
          # Use realistic UK surnames - no uniqueness required
          base_surnames = %w[
            Smith
            Johnson
            Williams
            Brown
            Jones
            Garcia
            Miller
            Davis
            Rodriguez
            Martinez
            Hernandez
            Lopez
            Gonzalez
            Wilson
            Anderson
            Thomas
            Taylor
            Moore
            Jackson
            Martin
            Lee
            Perez
            Thompson
            White
            Harris
            Sanchez
            Clark
            Ramirez
            Lewis
            Robinson
            Walker
            Young
            Allen
            King
            Wright
            Scott
            Torres
            Nguyen
            Hill
            Flores
            Green
            Adams
            Nelson
            Baker
            Hall
            Rivera
            Campbell
            Mitchell
            Carter
            Roberts
            Gomez
            Phillips
            Evans
            Turner
          ]
          base_surnames.sample
        end

        def full_name
          "#{first_name} #{last_name}"
        end
      end
    end

    class ContactGenerator < BaseGenerator
      class << self
        def email
          # Generate email with high entropy to minimize collisions
          # Use realistic UK domains
          domains = %w[
            gmail.com
            yahoo.co.uk
            hotmail.co.uk
            outlook.com
            btinternet.com
            sky.com
            virginmedia.com
            talktalk.net
            aol.com
            icloud.com
          ]
          username = "user#{large_random_number(8)}"
          "#{username}@#{domains.sample}"
        end

        def uk_phone
          # Generate UK phone numbers with large random space
          # Mobile numbers (07xxx xxxxxx) or landlines
          if rand < 0.7 # 70% mobile numbers
            "07#{large_random_number(9).to_s.rjust(9, "0")}"
          else # 30% landlines
            area_codes = %w[020 0121 0161 0113 0114 0115 0116 0117 0118 0131]
            "#{area_codes.sample}#{large_random_number(7).to_s.rjust(7, "0")}"
          end
        end

        def contact_method_description
          descriptions = [
            "Please call after #{rand(6..11)}pm",
            "Text messages preferred",
            "Email is best contact method",
            "Call during work hours only",
            "WhatsApp available on this number",
            "Leave voicemail if no answer",
            "Contact via partner if needed",
            "Weekends only please"
          ]
          descriptions.sample
        end
      end
    end

    class AddressGenerator < BaseGenerator
      class << self
        def uk_address_line
          # Generate realistic UK address with high entropy
          street_types = %w[
            Road
            Street
            Lane
            Avenue
            Close
            Drive
            Way
            Gardens
            Place
            Court
          ]
          street_names = %w[
            High
            Main
            Church
            Mill
            Victoria
            Albert
            Queen
            King
            Prince
            Royal
            Oak
            Elm
            Ash
            Beech
            Cedar
            Pine
            Maple
            Willow
            Rose
            Lily
            Hill
            Park
            View
            Green
            Common
            Heath
            Field
            Meadow
            Brook
          ]
          house_number = rand(1..999)
          "#{house_number} #{street_names.sample} #{street_types.sample}"
        end

        def uk_town
          # Use realistic UK towns/cities - no uniqueness required
          uk_towns = %w[
            London
            Birmingham
            Manchester
            Liverpool
            Leeds
            Sheffield
            Bristol
            Newcastle
            Nottingham
            Leicester
            Coventry
            Bradford
            Plymouth
            Southampton
            Reading
            Derby
            Dudley
            Northampton
            Portsmouth
            Luton
            Preston
            Aberdeen
            Sunderland
            Norwich
            Walsall
            Bournemouth
            Swindon
            Huddersfield
            Oxford
            Poole
            Bolton
            Middlesbrough
            Blackpool
            York
            Peterborough
            Stockport
            Brighton
            Slough
            Gloucester
            Watford
            Rotherham
            Cambridge
            Exeter
          ]
          uk_towns.sample
        end

        def uk_postcode
          # Generate valid UK postcode format with high entropy
          # Format: 1-2 letters, 1-2 digits, optional letter, space, digit, 2 letters
          area_letters = ("A".."Z").to_a.sample(rand(1..2)).join
          district = rand(1..99)
          sub_district = rand < 0.3 ? ("A".."Z").to_a.sample : ""
          sector = rand(0..9)
          unit = ("A".."Z").to_a.sample(2).join

          "#{area_letters}#{district}#{sub_district} #{sector}#{unit}"
        end
      end
    end

    class IdentifierGenerator < BaseGenerator
      class << self
        def nhs_number
          # Generate NHS number with guaranteed valid check digit
          # Strategy: Generate first 8 digits, pick random check digit, calculate 9th digit

          # Generate first 8 digits (first digit can't be 0)
          first_8_digits = [rand(1..9)] + Array.new(7) { rand(0..9) }

          # Pick a random valid check digit (0-9)

          # Calculate what the 9th digit needs to be to achieve this check digit
          last_two_digits = calculate_last_two_digits(first_8_digits)

          # Combine all digits
          all_digits = first_8_digits + last_two_digits
          all_digits.join
        end

        private

        def calculate_last_two_digits(first_8_digits)
          # NHS check digit algorithm can be written mathematically as (for sum = digit1*10 + digit2*9 + ... + digit8*3)
          # sum + 2*digit9 = 11 - check_digit (mod 11)
          # Equivalently this means: digit9 = 5 * (sum + check_digit) (mod 11)

          check_digit = rand(0..9)
          sum_of_first_8 =
            first_8_digits.each_with_index.sum do |digit, index|
              digit * (10 - index)
            end

          digit9 = 5 * (sum_of_first_8 + check_digit) % 11
          if digit9 == 10
            if check_digit.zero?
              check_digit = 1
              digit9 = 4
            else
              check_digit -= 1
              digit9 = 5
            end
          end
          [digit9, check_digit]
        end
      end
    end

    class TextGenerator < BaseGenerator
      class << self
        def relationship_description
          relationships = [
            "Mother",
            "Father",
            "Guardian",
            "Stepmother",
            "Stepfather",
            "Grandmother",
            "Grandfather",
            "Aunt",
            "Uncle",
            "Foster parent",
            "Legal guardian",
            "Adoptive parent",
            "Family friend",
            "Carer"
          ]
          relationships.sample
        end

        def generic_text(max_length = 100)
          # Generate realistic but generic text
          phrases = [
            "Please contact during normal hours",
            "Prefers email communication",
            "Has specific dietary requirements",
            "Requires interpreter services",
            "Emergency contact information updated",
            "Special arrangements needed",
            "Additional support required"
          ]
          text = "#{phrases.sample} - Ref: #{high_entropy_random(6)}"
          text[0, max_length]
        end
      end
    end

    # Main interface - delegates to specific generator classes
    class << self
      # Name generation methods
      delegate :first_name, to: :NameGenerator

      delegate :last_name, to: :NameGenerator

      delegate :full_name, to: :NameGenerator

      # Contact generation methods
      delegate :email, to: :ContactGenerator

      delegate :uk_phone, to: :ContactGenerator

      delegate :contact_method_description, to: :ContactGenerator

      # Address generation methods
      delegate :uk_address_line, to: :AddressGenerator

      delegate :uk_town, to: :AddressGenerator

      delegate :uk_postcode, to: :AddressGenerator

      # Identifier generation methods
      delegate :nhs_number, to: :IdentifierGenerator

      # Text generation methods
      delegate :relationship_description, to: :TextGenerator

      def generic_text(max_length = 100)
        TextGenerator.generic_text(max_length)
      end

      # Safely parse and call Faker methods without eval
      def parse_and_call_faker_method(method_string)
        # Parse "Faker::Name.first_name" into class and method
        if method_string =~ /^Faker::([A-Za-z]+)\.([a-z_]+)$/
          class_name = ::Regexp.last_match(1)
          method_name = ::Regexp.last_match(2)

          # Safely get the Faker class
          faker_class = Faker.const_get(class_name)

          # Call the method if it exists
          if faker_class.respond_to?(method_name)
            faker_class.send(method_name)
          else
            raise GenerationError, "Unknown Faker method: #{method_string}"
          end
        else
          raise GenerationError, "Invalid Faker method format: #{method_string}"
        end
      rescue NameError => e
        raise GenerationError,
              "Unknown Faker class in: #{method_string} (#{e.message})"
      end

      # Utility method to safely call any faker method from configuration
      # Uses independent thread approach - no database retries needed at this level
      def call_faker_method(method_string)
        case method_string
        when /^PIIAnonymizer::FakeDataGenerators\.(.+)$/
          method_name = ::Regexp.last_match(1)
          if respond_to?(method_name)
            send(method_name)
          else
            raise GenerationError,
                  "Unknown PIIAnonymizer method: #{method_name}"
          end
        when /^Faker::/
          # Handle standard Faker methods safely with UK locale
          BaseGenerator.with_uk_locale do
            parse_and_call_faker_method(method_string)
          end
        else
          raise GenerationError, "Unknown faker method format: #{method_string}"
        end
      rescue StandardError => e
        Rails.logger.error "Failed to generate fake data with method '#{method_string}': #{e.message}"
        # Return a safe fallback value with high entropy
        "GENERATION_ERROR_#{BaseGenerator.high_entropy_random(8)}"
      end
    end
  end
end
