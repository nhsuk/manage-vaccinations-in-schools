# frozen_string_literal: true

class CSVParser
  def initialize(data)
    @data = data
  end

  def call
    CSV.parse(
      data,
      converters:,
      empty_value: nil,
      encoding:,
      header_converters:,
      headers: true,
      skip_blanks: true,
      strip: true
    )
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :data

  def encoding
    return nil if data.blank?

    encoding = CharlockHolmes::EncodingDetector.detect(data)
    return nil if encoding.nil?

    encoding[:ruby_encoding]
  end

  def converters
    proc { |value| value&.strip.presence }
  end

  def header_converters
    proc { |value| value.strip.downcase.tr("-", "_").tr(" ", "_").to_sym }
  end
end
