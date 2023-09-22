require "faker"

require "example_campaign_generator"

desc "Generate example campaign data"
task :generate_example_campaign, [] => :environment do |_task, _args|
  Faker::Config.locale = "en-GB"
  target_filename = "/dev/stdout"

  seed = ENV["seed"]&.to_i
  patients = ENV["patients"]&.to_i
  type = ENV.fetch("type", "hpv").to_sym

  generator = ExampleCampaignGenerator.new(
    seed: seed,
    type: type,
    patients: patients,
  )
  data = generator.generate

  IO.write(target_filename, JSON.pretty_generate(data))
end
