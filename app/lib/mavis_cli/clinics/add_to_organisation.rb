# frozen_string_literal: true

module MavisCLI
  module Clinics
    class AddToOrganisation < Dry::CLI::Command
      desc "Add an existing clinic to an organisation"

      argument :organisation_ods_code,
               required: true,
               desc: "The ODS code of the organisation"
      argument :subteam, required: true, desc: "The subteam of the organisation"
      argument :clinic_ods_codes,
               type: :array,
               required: true,
               desc: "The ODS codes of the clinics"

      def call(organisation_ods_code:, subteam:, clinic_ods_codes:, **)
        MavisCLI.load_rails

        organisation = Organisation.find_by(ods_code: organisation_ods_code)

        if organisation.nil?
          warn "Could not find organisation."
          return
        end

        subteam = organisation.subteams.find_by(name: subteam)

        if subteam.nil?
          warn "Could not find subteam."
          return
        end

        ActiveRecord::Base.transaction do
          clinic_ods_codes.each do |ods_code|
            location = Location.clinic.find_by(ods_code:)

            if location.nil?
              warn "Could not find location: #{ods_code}"
              next
            end

            if !location.subteam_id.nil? && location.subteam_id != subteam.id
              warn "#{ods_code} previously belonged to #{location.subteam.name}"
            end

            location.update!(subteam:)
          end
        end
      end
    end
  end

  register "clinics" do |prefix|
    prefix.register "add-to-organisation", Clinics::AddToOrganisation
  end
end
