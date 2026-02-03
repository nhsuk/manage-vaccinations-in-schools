# frozen_string_literal: true

class RefactorIndexBatchesOnTeamIdAndNameAndExpiryAndVaccineId < ActiveRecord::Migration[
  8.1
]
  def change
    remove_index :batches, %i[team_id name expiry vaccine_id], unique: true

    add_index :batches, %i[team_id number expiry vaccine_id], unique: true
  end
end
