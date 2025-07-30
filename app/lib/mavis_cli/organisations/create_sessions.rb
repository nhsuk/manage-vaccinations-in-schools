# frozen_string_literal: true

module MavisCLI
  module Organisations
    class CreateSessions < Dry::CLI::Command
      desc "Create sessions for all locations"

      argument :ods_code,
               required: true,
               desc: "The ODS code of the organisation"

      option :academic_year,
             type: :integer,
             desc: "The academic year to create the sessions for"

      def call(ods_code:, academic_year: nil)
        MavisCLI.load_rails

        organisation = Organisation.find_by(ods_code:)

        if organisation.nil?
          warn "Could not find organisation."
          return
        end

        academic_year ||= AcademicYear.pending

        OrganisationSessionsFactory.call(organisation, academic_year:)
      end
    end
  end

  register "organisations" do |prefix|
    prefix.register "create-sessions", Organisations::CreateSessions
  end
end
