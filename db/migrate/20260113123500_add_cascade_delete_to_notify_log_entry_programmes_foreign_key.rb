# frozen_string_literal: true

class AddCascadeDeleteToNotifyLogEntryProgrammesForeignKey < ActiveRecord::Migration[
  8.1
]
  def change
    remove_foreign_key :notify_log_entry_programmes,
                       :notify_log_entries,
                       column: :notify_log_entry_id
    add_foreign_key :notify_log_entry_programmes,
                    :notify_log_entries,
                    column: :notify_log_entry_id,
                    on_delete: :cascade
  end
end
