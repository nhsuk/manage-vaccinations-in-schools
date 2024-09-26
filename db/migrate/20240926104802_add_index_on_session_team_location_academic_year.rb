# frozen_string_literal: true

class AddIndexOnSessionTeamLocationAcademicYear < ActiveRecord::Migration[7.2]
  def up
    delete_duplicate_sessions

    add_index :sessions, %i[team_id location_id academic_year], unique: true
  end

  def down
    remove_index :sessions, %i[team_id location_id academic_year]
  end

  private

  def delete_duplicate_sessions
    sessions =
      Session.where.not(
        id:
          Session.select("MIN(id)").group(
            :team_id,
            :location_id,
            :academic_year
          )
      )

    ConsentForm.where(session: sessions).delete_all

    Triage
      .joins(:session)
      .where(patient_sessions: { session: sessions })
      .delete_all

    VaccinationRecord
      .joins(:session)
      .where(patient_sessions: { session: sessions })
      .delete_all

    PatientSession.where(session: sessions).delete_all

    sessions.destroy_all
  end
end
