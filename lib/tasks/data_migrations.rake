# frozen_string_literal: true

namespace :data_migrations do
  desc "Remove trailing dots from all parent emails"
  task remove_trailing_dots_from_parent_emails: :environment do
    parents = Parent.where.not(email: nil).select { it.email.ends_with?(".") }

    puts "#{parents.count} parents with trailing dots in their email addresses"

    parents.each do |parent|
      email = parent.email.delete_suffix(".")
      parent.update_column(:email, email)
    end
  end

  desc "Removes school moves from any archived patients"
  task remove_school_moves_from_archived_patients: :environment do
    puts "#{ArchiveReason.count} archived patients"

    ArchiveReason
      .includes(:patient, :team)
      .find_each do |archive_reason|
        patient = archive_reason.patient
        team = archive_reason.team

        PatientArchiver.send(:new, patient:, team:, type: nil).send(
          :destroy_school_moves!
        )
      end
  end
end
