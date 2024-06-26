# frozen_string_literal: true

class RenameReasonForRefusalOtherToReasonForRefusalNotesOnConsent < ActiveRecord::Migration[
  7.1
]
  def change
    rename_column :consents,
                  :reason_for_refusal_other,
                  :reason_for_refusal_notes
  end
end
