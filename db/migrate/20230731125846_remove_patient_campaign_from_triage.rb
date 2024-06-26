# frozen_string_literal: true

class RemovePatientCampaignFromTriage < ActiveRecord::Migration[7.0]
  def change
    remove_reference :triage, :campaign
    remove_reference :triage, :patient
  end
end
