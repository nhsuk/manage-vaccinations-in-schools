# frozen_string_literal: true

module MavisCLI
  module Schools
    class MovePatients < Dry::CLI::Command
      desc "Move patients from one school to another"

      argument :source_urn, required: true, desc: "URN of the source team"
      argument :target_urn, required: true, desc: "URN of the target team"

      def call(source_urn:, target_urn:)
        MavisCLI.load_rails

        academic_year = AcademicYear.pending

        old_loc = Location.school.find_by_urn_and_site(source_urn)
        new_loc = Location.school.find_by_urn_and_site(target_urn)

        if old_loc.nil? || new_loc.nil?
          warn "Could not find one or both schools."
          return
        end

        unless PatientLocation
                 .joins(:patient)
                 .where(
                   patient: {
                     school: old_loc
                   },
                   academic_year:,
                   location: old_loc
                 )
                 .all?(&:safe_to_destroy?)
          raise "Some patient sessions at #{old_loc.urn} are not safe to destroy. Cannot complete transfer."
        end

        if !new_loc.subteam_id.nil? && new_loc.subteam_id != old_loc.subteam_id
          raise "#{new_loc.urn} belongs to #{new_loc.subteam.name}. Could not complete transfer."
        end
        new_loc.update!(subteam: old_loc.subteam)

        new_loc.import_year_groups!(
          old_loc.year_groups,
          academic_year:,
          source: "cli"
        )

        old_loc
          .location_programme_year_groups
          .find_each do |location_programme_year_group|
          location_year_group =
            new_loc.location_year_groups.find_by!(
              academic_year:,
              value: location_programme_year_group.location_year_group.value
            )
          location_programme_year_group.update_column(
            :location_year_group_id,
            location_year_group.id
          )
        end

        Session.where(
          location_id: old_loc.id
        ).update_all_and_sync_patient_teams(location_id: new_loc.id)
        Patient.where(school_id: old_loc.id).update_all(school_id: new_loc.id)
        PatientLocation.where(
          academic_year:,
          location_id: old_loc.id
        ).update_all_and_sync_patient_teams(location_id: new_loc.id)
        ConsentForm.where(location_id: old_loc.id).update_all(
          location_id: new_loc.id
        )
        ConsentForm.where(school_id: old_loc.id).update_all(
          school_id: new_loc.id
        )
        SchoolMove.where(
          school_id: old_loc.id
        ).update_all_and_sync_patient_teams(school_id: new_loc.id)
        Patient
          .where(school_id: new_loc.id)
          .find_each do |patient|
            SchoolMoveLogEntry.create!(patient:, school: new_loc)
          end
      end
    end
  end

  register "schools" do |prefix|
    prefix.register "move-patients", Schools::MovePatients
  end
end
