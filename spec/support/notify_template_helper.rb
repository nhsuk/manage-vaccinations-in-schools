# frozen_string_literal: true

module NotifyTemplateHelper
  def populate_notify_template(personalisation)
    return unless RSpec.current_example.metadata[:notify_template]

    template_path = Rails.root.join("spec/fixtures/notify_template.txt")

    unless File.exist?(template_path)
      puts "[WARNING] Template file not found at: #{template_path}"
      return
    end

    template = File.read(template_path)

    # Replace ((variable??text)) conditionals
    populated =
      template.gsub(/\(\((\w+)\?\?([^)]+)\)\)/) do
        key = ::Regexp.last_match(1).to_sym
        text = ::Regexp.last_match(2)
        personalisation[key] ? text : ""
      end

    # Replace ((variable)) placeholders
    populated =
      populated.gsub(/\(\((\w+)\)\)/) do
        key = ::Regexp.last_match(1).to_sym
        personalisation[key] || ""
      end

    puts "\n#{"=" * 80}"
    puts "POPULATED EMAIL TEMPLATE"
    puts "=" * 80
    puts populated
    puts "#{"=" * 80}\n"
  end
end

RSpec.configure { |config| config.include NotifyTemplateHelper }
