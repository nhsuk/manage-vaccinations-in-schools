# frozen_string_literal: true

module MavisCLI
  module Stats
    class Sessions < Dry::CLI::Command
      desc "Show session information"

      argument :session_slug, required: true, desc: "Session slug"

      def call(session_slug:)
        MavisCLI.load_rails

        session = Session.find_by!(slug: session_slug)
        programmes = session.programmes

        programmes.each do |programme|
          location_formatted = session.location.address_parts.join(", ")
          puts "Programme: #{programme.name}, Location: #{location_formatted}"

          headers = build_headers(programme)
          rows = [::Stats::Session.call(session:, programme:)]

          table = TableTennis.new(rows, headers:)
          puts table
        end
      end

      private

      def build_headers(programme)
        headers = {
          eligible_children: "Eligible children",
          no_response: "No response"
        }

        if programme.has_multiple_vaccine_methods?
          headers[:consent_nasal] = "Consent given for nasal spray"
          headers[:consent_injection] = "Consent given for injection"
        else
          headers[:consent_given] = "Consent given"
        end

        headers[:consent_refused] = "Consent refused"
        headers[:vaccinated] = "Vaccinated"

        headers
      end
    end
  end

  register "stats" do |prefix|
    prefix.register "sessions", Stats::Sessions
  end
end
