# frozen_string_literal: true

class DropProgrammesVaccines < ActiveRecord::Migration[7.2]
  def change
    drop_join_table :programmes, :vaccines
  end
end
