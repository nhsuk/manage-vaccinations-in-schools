# frozen_string_literal: true

namespace :notify_log_entries do
  desc "Set the recipient_deterministic column from the recipient column."
  task populate_deterministic_recipient: :environment do
    NotifyLogEntry
      .where(recipient_deterministic: nil)
      .find_each do |entry|
        entry.update!(receipient_deterministic: entry.recipient)
      end
  end
end
