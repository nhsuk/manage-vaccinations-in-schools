# frozen_string_literal: true

class ConsentFormBelongsToParent < ActiveRecord::Migration[7.1]
  def change
    add_reference :consent_forms, :parent, foreign_key: true
  end
end
