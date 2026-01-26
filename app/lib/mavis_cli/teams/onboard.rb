# frozen_string_literal: true

module MavisCLI
  module Teams
    class Onboard < Dry::CLI::Command
      desc "Onboard a new team, supports CIS2 and non-CIS2 envs"

      argument :path, desc: "The path to the onboarding configuration file"

      option :training,
             type: :boolean,
             desc:
               "Whether to set up the team for training. Not available in production."

      option :ods_code, desc: "The ODS code for the training team"
      option :workgroup, desc: "The workgroup for the training team"
      option :type,
             desc:
               "The type of team to onboard, either 'poc_only' or 'upload_only'",
             default: "poc_only"

      def call(
        path: nil,
        training: false,
        ods_code: nil,
        workgroup: nil,
        type: "poc_only",
        **
      )
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
            unless type.in?(Team.types.keys)
              warn "Invalid team type. Must be 'poc_only' or 'upload_only'."
              return
            end

            TrainingOnboardingConfiguration.call(ods_code:, workgroup:, type:)
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
