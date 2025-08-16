#frozen_string_literal: true

module MavisCLI
  module LocalAuthorities
    class ImportGIASCodes < Dry::CLI::Command
      desc "Import LocalAuthorities data"

      option :input_file,
             aliases: ["-i"],
             default: nil,
             desc: "Local Authorities GIAS codes zip file to use"
      
      def call(input_file: nil, **)
        MavisCLI.load_rails

        files_to_import = input_file ? Array(input_file) : Dir.glob("db/data/gias-la-codes-*.zip")
        progress_bar = MavisCLI.progress_bar(files_to_import.size)
          
        files_to_import.each do |file|
          puts "Importing file #{file}"
          import_file(file)
          progress_bar.increment
        end
      end

      def import_file(input_file)
        Zip::File.open(input_file) do |zip|
          csv_entry = zip.glob("*.csv").first
          csv_content = csv_entry.get_input_stream.read
        
          rows =
            CSV.parse(csv_content, headers: true, encoding: "ISO-8859-1:UTF-8")
          
          puts "importing #{rows.count - 1} GIAS/ONS LA code mappings"
          
          rows.each do |row|
            ons_code = row.to_h.select{|k,v| k =~ /\(ONS\)/ }.values.first
            gias_code = row.to_h.select{|k,v| k =~ /Get Information about Schools \(GIAS\)/ }.values.first

            LocalAuthority.where(gss_code: ons_code).update!(gias_local_authority_code: gias_code)
          end
        end
      end
    end
  end

  register "local_authorities" do |prefix|
    prefix.register "import_gias_codes", LocalAuthorities::ImportGIASCodes
  end
end
