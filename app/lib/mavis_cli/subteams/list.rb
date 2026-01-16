# frozen_string_literal: true

module MavisCLI
  module Subteams
    class List < Dry::CLI::Command
      desc "List subteams in Mavis"

      option :team_workgroup,
             desc: "The workgroup of the team to list subteams for"

      def call(team_workgroup: nil)
        MavisCLI.load_rails

        teams =
          if team_workgroup.present?
            team = Team.find_by(workgroup: team_workgroup)
            if team.nil?
              warn "Could not find team with workgroup #{team_workgroup}."
              return
            end

            team.subteams
          else
            Subteam.all
          end

        rows =
          teams.find_each.map do |subteam|
            subteam.slice(:id, :name, :team_id).merge(
              team_workgroup: subteam.team.workgroup,
              team_programmes: subteam.team.programmes.map(&:name).join(", ")
            )
          end

        puts TableTennis.new(
               rows,
               columns: %i[id name team_id team_workgroup team_programmes],
               zebra: true
             )
      end
    end
  end

  register "subteams" do |prefix|
    prefix.register "list", Subteams::List
  end
end
