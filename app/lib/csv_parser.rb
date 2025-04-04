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

  Field =
    Struct.new("Field", :value, :column, :row, :header) do
      delegate :blank?, :present?, to: :value

      alias_method :to_s, :value

      def cell = "#{column}#{row}"
    end

  private

  attr_reader :data

  ALPHABET = %w[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z].freeze
  COLUMNS = ALPHABET + ALPHABET.product(ALPHABET).map { _1 + _2 }

  def unconverted_headers
    @unconverted_headers ||=
      CSV.parse_line(data.lines.first, encoding:, strip: true)
  end

  def encoding
    @encoding ||=
      begin
        return nil if data.blank?

        encoding = CharlockHolmes::EncodingDetector.detect(data)
        return nil if encoding.nil?

        encoding[:ruby_encoding]
      end
  end

  def converters
    proc do |value, info|
      column = COLUMNS[info.index]
      row = info.line
      header = unconverted_headers[info.index]

      Field.new(value&.strip.presence, column, row, header)
    end
  end

  def header_converters
    proc { |value| value.strip.downcase.tr("-", "_").tr(" ", "_").to_sym }
  end
end
