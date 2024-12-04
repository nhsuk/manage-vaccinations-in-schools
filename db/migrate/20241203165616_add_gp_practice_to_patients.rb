# frozen_string_literal: true

class AddGPPracticeToPatients < ActiveRecord::Migration[7.2]
  def change
    add_reference :patients, :gp_practice, foreign_key: { to_table: :locations }
  end
end
