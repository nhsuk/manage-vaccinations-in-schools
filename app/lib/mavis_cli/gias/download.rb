# frozen_string_literal: true

# To get the latest version of the zip:
# 1. Go to https://get-information-schools.service.gov.uk/Downloads
# 2. Check "Establishment fields CSV"
# 3. Check "Establishment links CSV"
# 4. Submit
# 5. Download the zip file
# 6. Move the downloaded file to db/data/dfe-schools.zip
#
# Alternatively, you can run this task.

module MavisCLI
  module GIAS
    class Download < Dry::CLI::Command
      desc "Download GIAS schools data"

      option :output_file,
             aliases: ["-o"],
             default: "db/data/dfe-schools.zip",
             desc: "file path to write GIAS database to"

      def call(output_file:, **)
        base_logger = Logger.new($stdout)
        base_logger.formatter =
          proc { |_severity, _datetime, _progname, msg| "#{msg}\n" }
        logger = ActiveSupport::TaggedLogging.new(base_logger)

        ::GIAS.download(output_file:, logger:)
      end
    end
  end

  register "gias" do |prefix|
    prefix.register "download", GIAS::Download
  end
end
