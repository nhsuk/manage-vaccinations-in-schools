# frozen_string_literal: true

class RemoveSessionFromConsentForms < ActiveRecord::Migration[7.2]
  def change
    remove_reference :consent_forms, :session, foreign_key: true
  end
end
