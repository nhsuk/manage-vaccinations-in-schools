# frozen_string_literal: true

class RenameOrganisationToTeam < ActiveRecord::Migration[8.0]
  def change
    rename_table :organisations, :teams
    rename_table :organisation_programmes, :team_programmes
    rename_table :organisations_users, :teams_users

    rename_column :batches, :organisation_id, :team_id
    rename_column :class_imports, :organisation_id, :team_id
    rename_column :cohort_imports, :organisation_id, :team_id
    rename_column :consent_forms, :organisation_id, :team_id
    rename_column :consents, :organisation_id, :team_id
    rename_column :immunisation_imports, :organisation_id, :team_id
    rename_column :team_programmes, :organisation_id, :team_id
    rename_column :teams_users, :organisation_id, :team_id
    rename_column :school_moves, :organisation_id, :team_id
    rename_column :sessions, :organisation_id, :team_id
    rename_column :subteams, :organisation_id, :team_id
    rename_column :triage, :organisation_id, :team_id
  end
end
