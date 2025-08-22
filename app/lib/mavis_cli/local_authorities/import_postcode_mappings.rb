#frozen_string_literal: true

module MavisCLI
  module LocalAuthorities
    class ImportPostcodeMappings < Dry::CLI::Command
      desc "Import Postcode-to-LocalAuthority mappings"

      option :input_file,
             aliases: ["-i"],
             default: "db/data/ons-postcode-to-la-mappings.zip",
             desc: "ONS Postcode-to-Local-Authorities zip file to import"

      def call(input_file: nil, **)
        MavisCLI.load_rails
        import_file(input_file)
      end

      def import_file(input_file)
        postcode_field = "pcds"
        gss_code_field = "ladcd"
        objects_to_import = []
        batch_size = 1000

        Zip::File.open(input_file) do |zip|
          csv_entry = zip.glob("*.csv").first
          puts "importing postcode/gss code mappings from #{input_file}"
          csv_entry.get_input_stream do |stream|
            headers = stream.gets.split(",")
            postcode_index = headers.index(postcode_field)
            gss_code_index = headers.index(gss_code_field)

            progress_bar =
              ProgressBar.create!(
                starting_at: 0,
                total: stream.size,
                format: "%a %e %P% Processed: %c bytes of %C"
              )

            line_no = 1
            LocalAuthority::Postcode.transaction do
              puts "deleting #{LocalAuthority::Postcode.count} existing LocalAuthority::Postcode mappings"
              LocalAuthority::Postcode.delete_all

              stream.each_line do |line|
                # puts "parsing line #{line_no}"
                data = CSV.parse_line(line)
                postcode = data[postcode_index]
                gss_code = data[gss_code_index]

                objects_to_import << LocalAuthority::Postcode.new(
                  gss_code: gss_code,
                  value: postcode
                )
                line_no += 1
                progress_bar.progress = stream.pos
                next unless (objects_to_import.size % batch_size).zero?
                # puts "importing #{objects_to_import.size} objects"
                LocalAuthority::Postcode.import!(objects_to_import)
                objects_to_import.clear
              end
            end
          end
        end
      end
    end
  end

  register "local-authorities" do |prefix|
    prefix.register "import-postcode-mappings",
                    LocalAuthorities::ImportPostcodeMappings
  end
end
