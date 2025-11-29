# frozen_string_literal: true

class AddOriginalSessionToConsentForms < ActiveRecord::Migration[8.1]
  def change
    add_reference :consent_forms,
                  :original_session,
                  foreign_key: {
                    to_table: :sessions
                  }
  end
end
