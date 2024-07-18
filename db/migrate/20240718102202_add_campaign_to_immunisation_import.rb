# frozen_string_literal: true

class AddCampaignToImmunisationImport < ActiveRecord::Migration[7.1]
  def change
    # rubocop:disable Rails/NotNullColumn
    add_reference :immunisation_imports,
                  :campaign,
                  foreign_key: true,
                  null: false
    # rubocop:enable Rails/NotNullColumn
  end
end
