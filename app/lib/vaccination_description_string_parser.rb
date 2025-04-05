# frozen_string_literal: true

class VaccinationDescriptionStringParser
  def initialize(string)
    @string = string
  end

  def call
    return nil if string.blank?

    known_programme = KNOWN_PROGRAMMES.keys.find { string.starts_with?(it) }

    programme_name = KNOWN_PROGRAMMES[known_programme]
    return nil if known_programme.present? && programme_name.nil?

    vaccine_name = (string.split(" ").first if known_programme.blank?)
    return nil if known_programme.blank? && vaccine_name.blank?

    dose_sequence_string =
      if vaccine_name.present?
        string[vaccine_name.length..]
      elsif known_programme.present?
        string[known_programme.length..]
      end

    dose_sequence =
      begin
        Integer(dose_sequence_string)
      rescue ArgumentError, TypeError
        dose_sequence_string&.strip&.presence
      end

    { programme_name:, vaccine_name:, dose_sequence: }.compact
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :string

  KNOWN_PROGRAMMES = {
    "Flu" => "Flu",
    "HPV" => "HPV",
    "Human Papillomavirus" => "HPV",
    "MMR" => "MMR",
    "Measles/Mumps/Rubella" => "MMR",
    "MenACWY" => "MenACWY",
    "Meningococcal conjugate A,C, W135 + Y" => "MenACWY",
    "Td/IPV" => "Td/IPV"
  }.freeze
end
