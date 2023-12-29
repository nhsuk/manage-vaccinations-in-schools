require "faker"
require "example_campaign_generator"

# Generate example campaign data.

desc <<DESC
Generates a random example campaign and writes it to stdout.

Options (set these as env vars, e.g. seed=42):
  seed: Random seed used to make data reproducible.
  presets: Use preset values for the following options. These can be overridden with patients_* options. Available presets:
    - model_office
  sessions: Number of sessions to generate (default: 1)
  type: Type of campaign to generate, one of: hpv, flu (default: #{ExampleCampaignGenerator.default_type})
  username: Name of the user to be added to the team. An email address will be generated using this.
  users_json: A JSON string containing an array of users to be added to the team.
              Example: '[{"full_name": "John Doe", "email": "john.doe@nhs.net"}]'

Options controlling number of patients to generate:
#{ExampleCampaignGenerator.patient_options.map { |option| "  #{option}" }.join("\n")}
DESC
task :generate_example_campaign,
     [:example_file] => :environment do |_task, args|
  Faker::Config.locale = "en-GB"

  require "timecop"

  example_file = args.fetch(:example_file, "/dev/stdout")

  seed = ENV["seed"]&.to_i
  date = Time.zone.today
  # As we generate data with specific timestamps, we'll freeze time to be midday
  # today. A bit hacky but it's easier than having to stick the exact date AND
  # time into the example campaign generation specs.
  runtime = Time.zone.local(date.year, date.month, date.day, 12, 0, 0)

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
  users_json = ENV["users_json"]
  sessions = ENV["sessions"]

  data =
    Timecop.freeze(runtime) do
      generator =
        ExampleCampaignGenerator.new(
          seed:,
          username:,
          users_json:,
          sessions:,
          **campaign_options
        )
      generator.generate
    end

  IO.write(example_file, JSON.pretty_generate(data))
end
