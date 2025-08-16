#frozen_string_literal: true

module MavisCLI
  module LocalAuthorities
    class Import < Dry::CLI::Command
      desc "Import LocalAuthorities data"

      option :input_file,
             aliases: ["-i"],
             default: "db/data/uk-local-authorities.csv",
             desc: "Local Authorities CSV file to use"

      def call(input_file:, **)
        MavisCLI.load_rails

        input_file_path = File.expand_path(input_file)
        rows = CSV.read(input_file_path, headers: true)
        row_count = rows.length

        puts "Starting import of #{row_count} local_authorities."

        LocalAuthority.transaction do
          puts "Deleting #{LocalAuthority.count} existing local_authorities"
          LocalAuthority.delete_all
          local_authorities = []
          progress_bar = MavisCLI.progress_bar(row_count)

          rows.each do |row|
            local_authorities << LocalAuthority.from_my_society_import_row(row)
            progress_bar.increment
          end

          puts "Writing to database"
          LocalAuthority.import! local_authorities
        end

        puts "#{LocalAuthority.count} local_authorities"
      end
    end
  end

  register "local-authorities" do |prefix|
    prefix.register "import", LocalAuthorities::Import
  end
end
