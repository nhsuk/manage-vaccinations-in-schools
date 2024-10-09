# frozen_string_literal: true

class CreateParentEmailIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :parents, %i[email]
  end
end
