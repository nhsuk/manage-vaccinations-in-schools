# frozen_string_literal: true

class DataMigration::BackfillNotifyLogEntryProgrammes
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

    NotifyLogEntry.find_in_batches(batch_size: 10_000) do |notify_log_entries|
      notify_log_entry_programmes =
        notify_log_entries.flat_map do |notify_log_entry|
          notify_log_entry.programmes.map do |programme|
            disease_types =
              if programme.mmr?
                Programme::Variant::DISEASE_TYPES.fetch("mmr")
              else
                programme.disease_types
              end
            [notify_log_entry.id, programme.type, disease_types]
          end
        end

      NotifyLogEntry::Programme.import!(
        %i[notify_log_entry_id programme_type disease_types],
        notify_log_entry_programmes,
        on_duplicate_key_ignore: true
      )
      progress_bar.progress += notify_log_entries.size
    end

    progress_bar.finish
  end

  def self.call(...) = new(...).call

  private_class_method :new
end
