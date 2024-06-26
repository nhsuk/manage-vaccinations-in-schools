# frozen_string_literal: true

class AddObservedSessionAgreedFieldToRegistration < ActiveRecord::Migration[7.1]
  def change
    add_column :registrations, :user_research_observation_agreed, :boolean
  end
end
