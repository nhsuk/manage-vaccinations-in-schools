# frozen_string_literal: true

class AddReasonForRefusalToConsentFormProgrammes < ActiveRecord::Migration[8.0]
  def change
    change_table :consent_form_programmes, bulk: true do |t|
      t.integer :reason_for_refusal
      t.text :notes, null: false, default: ""
    end

    reversible do |direction|
      direction.up { execute <<~SQL }
        UPDATE consent_form_programmes
        SET reason_for_refusal = consent_forms.reason,
            notes = COALESCE(consent_forms.reason_notes, '')
        FROM consent_forms
        WHERE consent_forms.id = consent_form_programmes.consent_form_id
        AND consent_form_programmes.response = 1
      SQL

      direction.down { execute <<~SQL }
        UPDATE consent_forms
        SET reason = consent_form_programmes.reason_for_refusal, reason_notes = consent_form_programmes.notes
        FROM consent_form_programmes
        WHERE consent_form_programmes.consent_form_id = consent_forms.id
        AND consent_form_programmes.response = 1
      SQL
    end

    change_table :consent_forms, bulk: true do |t|
      t.remove :reason, type: :integer
      t.remove :reason_notes, type: :text
    end
  end
end
