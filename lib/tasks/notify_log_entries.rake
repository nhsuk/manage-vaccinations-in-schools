# frozen_string_literal: true

namespace :notify_log_entries do
  desc "Set the recipient column from the recipient_deterministic column."
  task populate_recipient: :environment do
    NotifyLogEntry
      .where(recipient: nil)
      .find_each do |entry|
        entry.update!(receipient: entry.recipient_deterministic)
      end
  end
end
