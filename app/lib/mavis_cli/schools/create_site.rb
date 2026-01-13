# frozen_string_literal: true

module MavisCLI
  module Schools
    class CreateSite < Dry::CLI::Command
      desc "Create a new site for an existing school, with an option to add it to the same team as the main site."

      argument :urn, required: true, desc: "School URN"
      argument :name, required: true, desc: "Name of the school"
      argument :site, required: true, desc: "Additional site"

      option :gias_establishment_number, desc: "GIAS establishment number"
      option :gias_local_authority_code, desc: "GIAS local authority code"
      option :gias_phase, desc: "GIAS phase (e.g. primary or secondary)"

      option :status, desc: "Status of the school", default: "open"
      option :systm_one_code, desc: "SystmOne code of the school"
      option :url, desc: "URL of the school"

      option :address_line_1, desc: "First line of address"
      option :address_line_2, desc: "Second line of address"
      option :address_town, desc: "Town of the address"
      option :address_postcode, desc: "Postcode of the address"

      option :add_to_team,
             type: :boolean,
             desc: "Add the new site to the same team as the main site",
             default: false

      def call(
        urn:,
        name:,
        site:,
        status: nil,
        systm_one_code: nil,
        url: nil,
        address_line_1: nil,
        address_line_2: nil,
        address_town: nil,
        address_postcode: nil,
        gias_establishment_number: nil,
        gias_local_authority_code: nil,
        gias_phase: nil,
        add_to_team: false,
        **
      )
        MavisCLI.load_rails

        school = Location.find_by(urn:, site: nil)

        raise "School with URN #{urn} doesn't exist." unless school
        if Location.exists?(urn:, site:)
          raise "Site #{site} already exists for URN #{urn}."
        end

        MavisCLI::Schools::Create.new.call(
          address_line_1: address_line_1 || school&.address_line_1,
          address_line_2: address_line_2 || school&.address_line_2,
          address_postcode: address_postcode || school&.address_postcode,
          address_town: address_town || school&.address_town,
          gias_establishment_number:
            gias_establishment_number || school&.gias_establishment_number,
          gias_local_authority_code:
            gias_local_authority_code || school&.gias_local_authority_code,
          gias_phase: gias_phase || school&.gias_phase,
          gias_year_groups: school&.gias_year_groups,
          name:,
          site:,
          status: status || school&.status,
          systm_one_code: systm_one_code || school&.systm_one_code,
          url: url || school&.url,
          urn:
        )

        location = Location.find_by!(urn:, site:)

        puts "Location #{location.id} has been created. URN: #{location.urn}, Site: #{location.site}"

        if add_to_team
          team = school.teams.uniq.sole
          subteam =
            TeamLocation.find_by!(
              academic_year: AcademicYear.pending,
              location: school
            ).subteam

          MavisCLI::Schools::AddToTeam.new.call(
            workgroup: team.workgroup,
            subteam: subteam.name,
            urns: [location.urn_and_site]
          )

          puts "Location #{location.id} has been added to team #{team.name}"
        end
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "create-site", Schools::CreateSite
  end
end
