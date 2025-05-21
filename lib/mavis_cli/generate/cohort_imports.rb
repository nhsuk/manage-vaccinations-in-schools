# frozen_string_literal: true

module MavisCLI
  extend Dry::CLI::Registry

  module Generate
    class CohortImports < Dry::CLI::Command
      desc "Generate cohort imports"
      option :patients,
             type: :integer,
             required: true,
             default: 10,
             desc: "Number of patients to create"

      def call(patients:)
        MavisCLI.load_rails

        ::Generate::CohortImports.call(patients:)
      end
    end
  end

  register "generate", aliases: ["g"] do |prefix|
    prefix.register "cohort_imports", Generate::CohortImports
  end
end
