# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_teams
#
#  sources    :integer          not null, is an Array
#  patient_id :bigint           not null, primary key
#  team_id    :bigint           not null, primary key
#
# Indexes
#
#  index_patient_teams_on_patient_id              (patient_id)
#  index_patient_teams_on_patient_id_and_team_id  (patient_id,team_id)
#  index_patient_teams_on_sources                 (sources) USING gin
#  index_patient_teams_on_team_id                 (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (team_id => teams.id) ON DELETE => cascade
#
class PatientTeam < ApplicationRecord
  extend ArrayEnum

  self.primary_key = %i[team_id patient_id]

  belongs_to :patient
  belongs_to :team

  scope :missing_sources, -> { where(sources: []) }

  array_enum sources: {
               patient_location: 0,
               archive_reason: 1,
               vaccination_record_session: 2,
               vaccination_record_organisation: 3,
               school_move_team: 4,
               school_move_school: 5
             }

  def add_source!(source)
    update!(sources: Array(sources) | [source.to_s])
  end

  def remove_source!(source)
    self.sources = sources.reject { it == source.to_s }
    sources.empty? ? delete : save!
  end
end
