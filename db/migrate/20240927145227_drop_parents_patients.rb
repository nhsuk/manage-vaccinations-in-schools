# frozen_string_literal: true

class DropParentsPatients < ActiveRecord::Migration[7.2]
  def change
    drop_join_table :parents, :patients
  end
end
