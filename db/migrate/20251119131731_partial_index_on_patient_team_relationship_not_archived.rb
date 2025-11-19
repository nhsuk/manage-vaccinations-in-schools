# frozen_string_literal: true

class PartialIndexOnPatientTeamRelationshipNotArchived < ActiveRecord::Migration[
  8.1
]
  disable_ddl_transaction!

  def change
    add_index :patient_teams,
              %i[team_id patient_id],
              where:
                "NOT (sources @> '{#{PatientTeam.sources.fetch(:archive_reason.to_s)}}'::integer[])",
              algorithm: :concurrently
  end
end
