# frozen_string_literal: true

module MavisCLI
  module Teams
    class Onboard < Dry::CLI::Command
      desc "Onboard a new team"

      argument :path,
               required: true,
               desc: "The path to the onboarding configuration file"

      def call(path:)
        MavisCLI.load_rails

        config = YAML.safe_load(File.read(path))

        onboarding = Onboarding.new(config)

        if onboarding.valid?
          onboarding.save!
        else
          onboarding.errors.full_messages.each { |message| puts message }
        end
      end
    end
  end

  register "teams" do |prefix|
    prefix.register "onboard", Teams::Onboard
  end
end
