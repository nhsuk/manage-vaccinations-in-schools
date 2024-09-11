# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id         :bigint           not null, primary key
#  end_date   :date
#  start_date :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :bigint           not null
#
# Indexes
#
#  index_cohorts_on_team_id  (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
class Cohort < ApplicationRecord
  belongs_to :team

  has_many :patients

  has_and_belongs_to_many :programmes
end
