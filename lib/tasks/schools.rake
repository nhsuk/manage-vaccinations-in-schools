# frozen_string_literal: true

namespace :schools do
  desc "Create a school for smoke testing in production."
  task smoke: :environment do
    Location.find_or_create_by!(
      name: "XXX Smoke Test School XXX",
      urn: "XXXXXX",
      type: :school,
      address_line_1: "1 Test Street",
      address_town: "Test Town",
      address_postcode: "TE1 1ST",
      gias_establishment_number: 999_999,
      gias_local_authority_code: 999_999,
      year_groups: [8, 9, 10, 11]
    )
  end

  desc "Transfer child records from one school to another."
  task :move_patients, %i[old_urn new_urn] => :environment do |_task, args|
    old_loc = Location.school.find_by(urn: args[:old_urn])
    new_loc = Location.school.find_by(urn: args[:new_urn])

    raise "Could not find one or both schools." if old_loc.nil? || new_loc.nil?

    unless PatientSession
             .joins(:patient, :session)
             .where(
               patient: {
                 school: old_loc
               },
               session: {
                 location: old_loc
               }
             )
             .all?(&:safe_to_destroy?)
      raise "Some patient sessions at #{old_loc.urn} are not safe to destroy. Cannot complete transfer."
    end

    if !new_loc.team_id.nil? && new_loc.team_id != old_loc.team_id
      raise "#{new_loc.urn} belongs to #{new_loc.team.name}. Could not complete transfer."
    end
    new_loc.update!(team: old_loc.team)

    Session.where(location_id: old_loc.id).update_all(location_id: new_loc.id)
    Patient.where(school_id: old_loc.id).update_all(school_id: new_loc.id)
    ConsentForm.where(location_id: old_loc.id).update_all(
      location_id: new_loc.id
    )
    ConsentForm.where(school_id: old_loc.id).update_all(school_id: new_loc.id)
    SchoolMove.where(school_id: old_loc.id).update_all(school_id: new_loc.id)
    Patient
      .where(school_id: new_loc.id)
      .find_each do |patient|
        SchoolMoveLogEntry.create!(patient:, school: new_loc)
      end
  end
end
