# frozen_string_literal: true

module MavisCLI
  module Teams
    class Onboard < Dry::CLI::Command
      desc "Onboard a new team"

      argument :path, desc: "The path to the onboarding configuration file"

      option :training,
             type: :boolean,
             desc:
               "Whether to set up the team for training. Not available in production."

      option :ods_code, desc: "The ODS code for the training team"
      option :workgroup, desc: "The workgroup for the training team"

      def call(path: nil, training: false, ods_code: nil, workgroup: nil, **)
        MavisCLI.load_rails

        if training && Rails.env.production?
          warn "Cannot create a training team in production."
          return
        end

        if !training && path.blank?
          warn "Specify the path to a configuration file."
          return
        end

        config =
          if training
            TrainingOnboardingConfiguration.call(ods_code:, workgroup:)
          else
            YAML.safe_load(File.read(path))
          end

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
