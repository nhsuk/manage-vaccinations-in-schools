# frozen_string_literal: true

class SyncPatientTeamJob < ApplicationJob
  queue_as :cache

  def perform(model_class, id_array)
    return if id_array.blank?

    model_class.all.sync_patient_teams_table_on_patient_ids(id_array)
  end
end
