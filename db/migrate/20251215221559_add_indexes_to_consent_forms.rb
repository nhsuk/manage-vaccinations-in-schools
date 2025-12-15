# frozen_string_literal: true

class AddIndexesToConsentForms < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :consent_forms,
              :id,
              where: "recorded_at IS NOT NULL",
              name: "index_consent_forms_on_recorded",
              algorithm: :concurrently

    add_index :consent_forms,
              :id,
              where: "recorded_at IS NOT NULL AND archived_at IS NULL",
              name: "index_consent_forms_on_unmatched_and_not_archived",
              algorithm: :concurrently
  end
end
