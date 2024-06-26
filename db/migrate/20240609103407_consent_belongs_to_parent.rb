# frozen_string_literal: true

class ConsentBelongsToParent < ActiveRecord::Migration[7.1]
  def change
    add_reference :consents, :parent, foreign_key: true
  end
end
