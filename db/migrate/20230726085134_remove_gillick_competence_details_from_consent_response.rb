# frozen_string_literal: true

class RemoveGillickCompetenceDetailsFromConsentResponse < ActiveRecord::Migration[
  7.0
]
  def change
    remove_column :consent_responses, :gillick_competence_details, :text
  end
end
