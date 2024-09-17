# frozen_string_literal: true

# == Schema Information
#
# Table name: cohorts
#
#  id                      :bigint           not null, primary key
#  reception_starting_year :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  team_id                 :bigint           not null
#
# Indexes
#
#  index_cohorts_on_team_id                              (team_id)
#  index_cohorts_on_team_id_and_reception_starting_year  (team_id,reception_starting_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#
describe Cohort do
  subject(:cohort) { build(:cohort) }

  it { should be_valid }
end
