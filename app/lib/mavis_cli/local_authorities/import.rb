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
        row_count = Open3.capture2("wc", "-l", input_file_path).first.to_i

        puts "Starting import of #{row_count - 1} local_authorities."

        LocalAuthority.transaction do
          puts "Deleting #{LocalAuthority.count} existing local_authorities"
          LocalAuthority.delete_all
          local_authorities = []
          progress_bar = MavisCLI.progress_bar(row_count + 1)

          CSV.foreach(input_file_path, headers: true) do |row|
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

  register "local_authorities" do |prefix|
    prefix.register "import", LocalAuthorities::Import
  end
end
