require "faker"
require "example_campaign_generator"

# Generate example campaign data.

desc <<DESC
Generates a random example campaign and writes it to stdout.

Option (set these as env vars, e.g. seed=42):
  seed: Random seed used to make data reproducible.
  presets: Use preset values for the following options. These can be overridden with patients_* options. Available presets:
    - model_office
  type: Type of campaign to generate, one of: hpv, flu (default: ExampleCampaignGenerator.default_type)
  username: Name of the user to be added to the team. An email address will be generated using this.

Options controlling number of patients to generate:
#{ExampleCampaignGenerator.patient_options.map { |option| "  #{option}" }.join("\n")}
DESC
task :generate_example_campaign,
     [:example_file] => :environment do |_task, args|
  Faker::Config.locale = "en-GB"

  example_file = args.fetch(:example_file, "/dev/stdout")

  seed = ENV["seed"]&.to_i

  campaign_options = {}
  campaign_options[:type] = ENV["type"]&.to_sym
  campaign_options[:presets] = ENV["presets"] if ENV["presets"]
  ExampleCampaignGenerator.patient_options.each do |option|
    campaign_options[option] = ENV[option.to_s].to_i if ENV[option.to_s]
  end
  if campaign_options[:presets].blank? &&
       (campaign_options.keys & ExampleCampaignGenerator.patient_options).empty?
    campaign_options[:presets] = :default
  end

  username = ENV["username"]

  generator = ExampleCampaignGenerator.new(seed:, username:, **campaign_options)
  data = generator.generate

  IO.write(example_file, JSON.pretty_generate(data))
end
