# frozen_string_literal: true

module MavisCLI
  module Organisations
    class AddProgramme < Dry::CLI::Command
      desc "Adds a programme to an organisation"

      argument :ods_code,
               required: true,
               desc: "The ODS code of the organisation"

      argument :type, required: true, desc: "The type of programme to add"

      def call(ods_code:, type:)
        MavisCLI.load_rails

        organisation = Organisation.find_by(ods_code:)

        if organisation.nil?
          warn "Could not find organisation."
          return
        end

        programme = Programme.find_by(type:)

        if programme.nil?
          warn "Could not find programme."
          return
        end

        if organisation.programmes.include?(programme)
          warn "Programme is already part of the organisation."
          return
        end

        ActiveRecord::Base.transaction do
          OrganisationProgramme.create!(organisation:, programme:)

          programmes = organisation.reload.programmes

          GenericClinicFactory.call(organisation:)

          organisation.locations.find_each do |location|
            location.create_default_programme_year_groups!(programmes)
          end
        end
      end
    end
  end

  register "organisations" do |prefix|
    prefix.register "add-programme", Organisations::AddProgramme
  end
end
