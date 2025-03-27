# frozen_string_literal: true

class RemoveUnneededIndexes < ActiveRecord::Migration[8.0]
  def change
    remove_index :batches,
                 name: "index_batches_on_organisation_id",
                 column: :organisation_id
    remove_index :consent_form_programmes,
                 name: "index_consent_form_programmes_on_programme_id",
                 column: :programme_id
    remove_index :consent_notification_programmes,
                 name: "index_consent_notification_programmes_on_programme_id",
                 column: :programme_id
    remove_index :organisation_programmes,
                 name: "index_organisation_programmes_on_organisation_id",
                 column: :organisation_id
    remove_index :parent_relationships,
                 name: "index_parent_relationships_on_parent_id",
                 column: :parent_id
    remove_index :patient_sessions,
                 name: "index_patient_sessions_on_patient_id",
                 column: :patient_id
    remove_index :school_moves,
                 name: "index_school_moves_on_patient_id",
                 column: :patient_id
    remove_index :session_attendances,
                 name: "index_session_attendances_on_patient_session_id",
                 column: :patient_session_id
    remove_index :session_dates,
                 name: "index_session_dates_on_session_id",
                 column: :session_id
    remove_index :session_notifications,
                 name: "index_session_notifications_on_patient_id",
                 column: :patient_id
    remove_index :session_programmes,
                 name: "index_session_programmes_on_session_id",
                 column: :session_id
    remove_index :sessions,
                 name: "index_sessions_on_organisation_id",
                 column: :organisation_id
    remove_index :teams,
                 name: "index_teams_on_organisation_id",
                 column: :organisation_id
  end
end
