# frozen_string_literal: true

class SwapConsentAndConsentFormAssociations < ActiveRecord::Migration[8.0]
  def change
    add_reference :consents, :consent_form, foreign_key: true

    reversible do |direction|
      direction.up { execute <<~SQL }
        UPDATE consents
        SET consent_form_id = consent_forms.id
        FROM consent_forms
        WHERE consents.id = consent_forms.consent_id 
      SQL

      direction.down { execute <<~SQL }
        UPDATE consent_forms
        SET consent_id = consents.id
        FROM consents
        WHERE consent_forms.id = consents.consent_form_id 
      SQL
    end

    remove_reference :consent_forms, :consent, foreign_key: true
  end
end
