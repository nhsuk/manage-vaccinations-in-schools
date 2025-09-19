# frozen_string_literal: true

class SwapConsentAndConsentFormAssociations < ActiveRecord::Migration[8.0]
  def change
    add_reference :consents, :consent_form, foreign_key: true

    reversible do |direction|
      direction.up do
        ConsentForm
          .where.not(consent_id: nil)
          .find_each do |consent_form|
            consent = Consent.find(consent_form.consent_id)
            consent.update_column(:consent_form_id, consent_form.id)
          end
      end

      direction.down do
        Consent
          .where.not(consent_form_id: nil)
          .find_each do |consent|
            consent_form = ConsentForm.find(consent.consent_form_id)
            consent_form.update_column(:consent_id, consent.id)
          end
      end
    end

    remove_reference :consent_forms, :consent, foreign_key: true
  end
end
