# frozen_string_literal: true

module MavisCLI
  module Schools
    class Create < Dry::CLI::Command
      desc "Create a new school"

      argument :urn, required: true, desc: "School URN"
      argument :name, required: true, desc: "Name of the school"
      argument :gias_establishment_number,
               required: true,
               desc: "GIAS establishment number"
      argument :gias_local_authority_code,
               required: true,
               desc: "GIAS local authority code"

      option :site, desc: "Additional site "
      option :status, desc: "Status of the school", default: "open"
      option :systm_one_code, desc: "SystmOne code of the school"
      option :url, desc: "URL of the school"

      option :address_line_1, desc: "First line of address"
      option :address_line_2, desc: "Second line of address"
      option :address_town, desc: "Town of the address"
      option :address_postcode, desc: "Postcode of the address"

      option :year_groups,
             type: :array,
             desc: "Year groups taught at the school"

      def call(
        urn:,
        name:,
        gias_establishment_number:,
        gias_local_authority_code:,
        site: nil,
        status: "open",
        systm_one_code: nil,
        url: nil,
        address_line_1: nil,
        address_line_2: nil,
        address_town: nil,
        address_postcode: nil,
        year_groups: []
      )
        MavisCLI.load_rails

        location =
          Location.create!(
            address_line_1:,
            address_line_2:,
            address_postcode:,
            address_town:,
            gias_establishment_number:,
            gias_local_authority_code:,
            name:,
            site:,
            status:,
            systm_one_code:,
            type: "school",
            url:,
            urn:,
            year_groups:
          )

        puts "Location #{location.id} has been created."
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "create", Schools::Create
  end
end
