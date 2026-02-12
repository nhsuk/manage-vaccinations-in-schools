#frozen_string_literal: true

module MavisCLI
  module GIAS
    class Import < Dry::CLI::Command
      desc "Import GIAS schools data"

      option :input_file,
             aliases: ["-i"],
             default: "db/data/dfe-schools.zip",
             desc: "GIAS database file to use"

      def call(input_file:, **)
        MavisCLI.load_rails

        row_count = ::GIAS.row_count(input_file)
        puts "Starting import of #{row_count - 1} schools."
        progress_bar = MavisCLI.progress_bar(row_count)

        ::GIAS.import(input_file:, progress_bar:)
      end
    end
  end

  register "gias" do |prefix|
    prefix.register "import", GIAS::Import
  end
end
