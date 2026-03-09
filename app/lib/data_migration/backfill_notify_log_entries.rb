# frozen_string_literal: true

class DataMigration::BackfillNotifyLogEntries
  def call
    progress_bar =
      # rubocop:disable Rails/SaveBang
      ProgressBar.create(
        total: NotifyLogEntry.count,
        format: "%a %b\u{15E7}%i %p%% %t",
        progress_mark: " ",
        remainder_mark: "\u{FF65}"
      )
    # rubocop:enable Rails/SaveBang

    NotifyLogEntry.find_in_batches do |notify_log_entries|
      notify_log_entries.filter_map do |notify_log_entry|
        template_name = resolved_template_name(notify_log_entry)

        next unless template_name

        purpose = NotifyLogEntry.purpose_for_template_name(template_name)

        next unless purpose

        notify_log_entry.update_column(
          :purpose,
          NotifyLogEntry.purposes.fetch(purpose)
        )
      end

      progress_bar.progress += 1
    end

    progress_bar.finish
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  def resolved_template_name(notify_log_entry)
    NotifyTemplate.find_by_id(
      notify_log_entry.template_id,
      channel: notify_log_entry.type.to_sym
    )&.name
  end
end
