#frozen_string_literal: true

module MavisCLI
  module GIAS
    class CheckImport < Dry::CLI::Command
      desc "Check what changes will be introduced with a GIAS import"

      option :input_file,
             aliases: ["-i"],
             default: "db/data/dfe-schools.zip",
             desc: "GIAS database file to use"

      def call(input_file:, **)
        MavisCLI.load_rails

        logger = Logger.new($stdout)
        logger.formatter =
          proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }

        row_count = ::GIAS.row_count(input_file)
        progress_bar = MavisCLI.progress_bar(row_count)

        results = ::GIAS.check_import(input_file:, progress_bar:)

        ::GIAS.log_import_check_results(results, logger:)
      end
    end
  end

  register "gias" do |prefix|
    prefix.register "check-import", GIAS::CheckImport
  end
end
