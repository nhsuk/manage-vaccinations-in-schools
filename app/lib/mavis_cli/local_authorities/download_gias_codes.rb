# frozen_string_literal: true

# To get the latest version of the zip:
# 1. Go to https://get-information-schools.service.gov.uk/Downloads
# 2. Check "Establishment fields CSV"
# 3. Submit
# 4. Download the zip file
# 5. Place it in db/data/dfe-schools.zip
#
# Alternatively, you can run this task.

module MavisCLI
  module LocalAuthorities
    class DownloadGIASCodes < Dry::CLI::Command
      desc "Download GIAS Local Authority code mappings"

      def call
        MavisCLI.load_rails

        require "mechanize"

        puts "Starting data download process..."
        agent = Mechanize.new
        agent.user_agent_alias = "Mac Safari"

        progress_bar = MavisCLI.progress_bar(4)

        ["English", "Welsh", "Other"].each do |la_type|
          puts "downloading #{la_type} LA GIAS code mappings"
          download(la_type:, agent:)
        end
      end

      def download(la_type:, agent:)
        puts "Visiting the GIAS data tables downloads page"
        page =
          agent.get("https://get-information-schools.service.gov.uk/Guidance/LaNameCodes/DataTables")

        puts "Selecting #{la_type} LAs"
        form = page.form_with(action: "/Guidance/LaNameCodes/DataTables/SelectFormat")
        form.radiobuttons_with(value: /#{la_type}/i).each do |field|
          field.check
        end

        puts "Submitting the form"
        format_page = form.submit

        puts "Selecting format"
        form = format_page.form_with(action: "/Guidance/LaNameCodes/DataTables/SelectFormat/GenerateDownload")
        form.radiobuttons_with(name: /CSV/i).each do |field|
          field.check
        end

        puts "Submitting the form"
        download_page = form.submit

        puts "Clicking the Download button"
        download_button = download_page.link_with(id: "help-guidance-lanamecodes-download-button")
        download_file = agent.click(download_button)
        output_path = File.expand_path("db/data/gias-la-codes-#{la_type.downcase}.zip")
        download_file.save!(output_path)
      end
    end
  end

  register "local_authorities" do |prefix|
    prefix.register "download_gias_codes", LocalAuthorities::DownloadGIASCodes
  end
end
