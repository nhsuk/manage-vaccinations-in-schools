# frozen_string_literal: true

module MavisCLI
  module Schools
    class AddProgrammeYearGroup < Dry::CLI::Command
      desc "Add programme year groups to a school"

      argument :urn, required: true, desc: "The URN of the school"
      argument :programme_type,
               required: true,
               desc: "The programme to add year groups to"
      argument :year_groups,
               type: :array,
               required: true,
               desc: "The year groups to add"

      def call(urn:, programme_type:, year_groups:, **)
        MavisCLI.load_rails

        location = Location.school.find_by_urn_and_site(urn)

        if location.nil?
          warn "Could not find school."
          return
        end

        programme = Programme.find(programme_type)

        if programme.nil?
          warn "Could not find programme."
          return
        end

        academic_year = AcademicYear.pending

        ActiveRecord::Base.transaction do
          year_groups.each do |year_group|
            location_year_group =
              Location::YearGroup.create_with(source: "cli").find_or_create_by!(
                location:,
                academic_year:,
                value: year_group
              )

            Location::ProgrammeYearGroup.find_or_create_by!(
              location_year_group:,
              programme_type:
            )
          end

          location.sessions.find_each do |session|
            if session.programmes.include?(programme)
              session.sync_location_programme_year_groups!(
                programmes: session.programmes
              )
            end
          end
        end
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "add-programme-year-group", Schools::AddProgrammeYearGroup
  end
end
