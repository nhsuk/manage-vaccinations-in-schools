# frozen_string_literal: true

# == Schema Information
#
# Table name: location_programme_year_groups
#
#  id                     :bigint           not null, primary key
#  programme_type         :enum
#  location_year_group_id :bigint           not null
#  programme_id           :bigint           not null
#
# Indexes
#
#  idx_on_location_year_group_id_programme_id_405f51181e           (location_year_group_id,programme_id) UNIQUE
#  index_location_programme_year_groups_on_location_year_group_id  (location_year_group_id)
#  index_location_programme_year_groups_on_programme_id            (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_year_group_id => location_year_groups.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#
describe Location::ProgrammeYearGroup do
  subject { build(:location_programme_year_group) }

  describe "associations" do
    it { should belong_to(:location_year_group) }
    it { should belong_to(:programme) }
  end
end
