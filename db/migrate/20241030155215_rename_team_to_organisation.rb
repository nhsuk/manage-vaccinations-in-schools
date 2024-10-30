# frozen_string_literal: true

class RenameTeamToOrganisation < ActiveRecord::Migration[7.2]
  def change
    rename_table :teams, :organisations
    rename_table :team_programmes, :organisation_programmes
    rename_table :teams_users, :organisations_users

    rename_column :batches, :team_id, :organisation_id
    rename_column :class_imports, :team_id, :organisation_id
    rename_column :cohort_imports, :team_id, :organisation_id
    rename_column :cohorts, :team_id, :organisation_id
    rename_column :consent_forms, :team_id, :organisation_id
    rename_column :consents, :team_id, :organisation_id
    rename_column :immunisation_imports, :team_id, :organisation_id
    rename_column :locations, :team_id, :organisation_id
    rename_column :organisation_programmes, :team_id, :organisation_id
    rename_column :organisations_users, :team_id, :organisation_id
    rename_column :sessions, :team_id, :organisation_id
    rename_column :triage, :team_id, :organisation_id
  end
end
