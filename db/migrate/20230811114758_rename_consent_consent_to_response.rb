# frozen_string_literal: true

class RenameConsentConsentToResponse < ActiveRecord::Migration[7.0]
  def change
    rename_column :consents, :consent, :response
  end
end
