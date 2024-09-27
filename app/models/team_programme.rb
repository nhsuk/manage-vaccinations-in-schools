# frozen_string_literal: true

# == Schema Information
#
# Table name: team_programmes
#
#  id           :bigint           not null, primary key
#  programme_id :bigint           not null
#  team_id      :bigint           not null
#
# Indexes
#
#  index_team_programmes_on_programme_id              (programme_id)
#  index_team_programmes_on_team_id                   (team_id)
#  index_team_programmes_on_team_id_and_programme_id  (team_id,programme_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#
class TeamProgramme < ApplicationRecord
  audited

  belongs_to :programme
  belongs_to :team
end
