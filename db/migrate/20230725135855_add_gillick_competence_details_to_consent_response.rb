# frozen_string_literal: true

class AddGillickCompetenceDetailsToConsentResponse < ActiveRecord::Migration[
  7.0
]
  def change
    add_column :consent_responses, :gillick_competence_details, :text
  end
end
