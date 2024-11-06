# frozen_string_literal: true

class RenameConsentReasonForRefusalNotes < ActiveRecord::Migration[7.2]
  def change
    change_table :consents, bulk: true do |t|
      t.rename :reason_for_refusal_notes, :notes
      t.change_default :notes, from: nil, to: ""
      t.change_null :notes, false, ""
    end
  end
end
