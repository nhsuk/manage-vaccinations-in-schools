# frozen_string_literal: true

module MavisCLI
  module Teams
    class List < Dry::CLI::Command
      desc "List teams in Mavis"

      option :ods_code,
             desc: "The ODS code of the organisation to list teams for"

      def call(ods_code: nil)
        MavisCLI.load_rails

        teams =
          if ods_code.present?
            organisation = Organisation.find_by(ods_code:)
            if organisation.nil?
              raise ArgumentError,
                    "Could not find organisation with ODS code: #{ods_code}"
            end

            organisation.teams
          else
            Team.all
          end.map do |team|
            team.attributes.merge(ods_code: team.organisation.ods_code)
          end

        puts TableTennis.new(
               teams,
               columns: %i[id name ods_code workgroup],
               zebra: true
             )
      end
    end
  end

  register "teams" do |prefix|
    prefix.register "list", Teams::List
  end
end
