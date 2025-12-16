# frozen_string_literal: true

namespace :data_migration do
  desc "Remove clinic session notifications which are no longer used."
  task delete_clinic_session_notifications: :environment do
    SessionNotification.where(type: [1, 2]).delete_all
  end

  desc "Delete sessions that have not been scheduled."
  task delete_unscheduled_sessions: :environment do
    destroyed_sessions =
      Session
        .where(dates: [])
        .find_each
        .filter_map do |session|
          next if session.consent_notifications.exists?
          next if session.session_notifications.exists?
          next if session.vaccination_records.exists?
          next if ConsentForm.where(original_session: session).exists?

          session.tap(&:destroy!)
        end

    puts "Deleted #{destroyed_sessions.count} sessions"
  end

  desc "Set disease types on various tables (batched)"
  task set_disease_types_batched: :environment do
    batch_size = 10_000

    total =
      Programme::DISEASE_TYPES.sum do |programme_type, _|
        [
          Consent,
          Patient::ConsentStatus,
          Patient::ProgrammeStatus
        ].sum { |klass| klass.where(disease_types: nil, programme_type:).count }
      end

    progress_bar =
      # rubocop:disable Rails/SaveBang
      ProgressBar.create(
        total:,
        format: "%a %b\u{15E7}%i %p%% %t",
        progress_mark: " ",
        remainder_mark: "\u{FF65}"
      )
    # rubocop:enable Rails/SaveBang

    Programme::DISEASE_TYPES.each do |programme_type, disease_types|
      [
        Consent,
        Patient::ConsentStatus,
        Patient::ProgrammeStatus
      ].each do |klass|
        loop do
          updated =
            klass
              .where(disease_types: nil, programme_type:)
              .limit(batch_size)
              .update_all(disease_types:)

          break if updated.zero?

          progress_bar.progress += updated
        end
      end
    end

    progress_bar.finish
  end
end
