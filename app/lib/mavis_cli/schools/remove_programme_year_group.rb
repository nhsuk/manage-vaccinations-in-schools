# frozen_string_literal: true

module MavisCLI
  module Schools
    class RemoveProgrammeYearGroup < Dry::CLI::Command
      desc "Remove programme year groups from a school"

      argument :urn, required: true, desc: "The URN of the school"
      argument :programme_type,
               required: true,
               desc: "The programme to remove year groups from"
      argument :year_groups,
               type: :array,
               required: true,
               desc: "The year groups to remove"

      def call(urn:, programme_type:, year_groups:, **)
        MavisCLI.load_rails

        location = Location.school.find_by_urn_and_site(urn)

        if location.nil?
          warn "Could not find school."
          return
        end

        programme = Programme.find_by(type: programme_type)

        if programme.nil?
          warn "Could not find programme."
          return
        end

        location
          .location_programme_year_groups
          .where(location_year_group: { value: year_groups }, programme:)
          .destroy_all
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "remove-programme-year-group",
                    Schools::RemoveProgrammeYearGroup
  end
end
