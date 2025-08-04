# frozen_string_literal: true

desc "Onboard a team from a configuration file."
task :onboard, [:filename] => :environment do |_, args|
  config = YAML.safe_load(File.read(args[:filename]))

  onboarding = Onboarding.new(config)

  if onboarding.valid?
    onboarding.save!
  else
    onboarding.errors.full_messages.each { |message| puts message }
  end
end
