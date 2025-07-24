# frozen_string_literal: true

module MavisCLI
  module Clinics
    class AddToOrganisation < Dry::CLI::Command
      desc "Add an existing clinic to an organisation"

      argument :organisation_ods_code,
               required: true,
               desc: "The ODS code of the organisation"
      argument :team, required: true, desc: "The team of the organisation"
      argument :clinic_ods_codes,
               type: :array,
               required: true,
               desc: "The ODS codes of the clinics"

      def call(organisation_ods_code:, team:, clinic_ods_codes:, **)
        MavisCLI.load_rails

        organisation = Organisation.find_by(ods_code: organisation_ods_code)

        if organisation.nil?
          warn "Could not find organisation."
          return
        end

        team = organisation.teams.find_by(name: team)

        if team.nil?
          warn "Could not find team."
          return
        end

        ActiveRecord::Base.transaction do
          clinic_ods_codes.each do |ods_code|
            location = Location.clinic.find_by(ods_code:)

            if location.nil?
              warn "Could not find location: #{ods_code}"
              next
            end

            if !location.team_id.nil? && location.team_id != team.id
              warn "#{ods_code} previously belonged to #{location.team.name}"
            end

            location.update!(team:)
          end
        end
      end
    end
  end

  register "clinics" do |prefix|
    prefix.register "add-to-organisation", Clinics::AddToOrganisation
  end
end
