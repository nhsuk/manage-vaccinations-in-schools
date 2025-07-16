# frozen_string_literal: true

# == Schema Information
#
# Table name: location_programme_year_groups
#
#  id           :bigint           not null, primary key
#  year_group   :integer          not null
#  location_id  :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  idx_on_location_id_programme_id_year_group_4bee220488  (location_id,programme_id,year_group) UNIQUE
#  index_location_programme_year_groups_on_location_id    (location_id)
#  index_location_programme_year_groups_on_programme_id   (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#
describe Location::ProgrammeYearGroup do
  subject { build(:location_programme_year_group) }

  describe "associations" do
    it { should belong_to(:location) }
    it { should belong_to(:programme) }
  end
end
