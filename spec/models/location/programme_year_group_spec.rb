# frozen_string_literal: true

# == Schema Information
#
# Table name: location_programme_year_groups
#
#  id                     :bigint           not null, primary key
#  academic_year          :integer          not null
#  year_group             :integer          not null
#  location_id            :bigint           not null
#  location_year_group_id :bigint           not null
#  programme_id           :bigint           not null
#
# Indexes
#
#  idx_on_location_id_academic_year_programme_id_year__6ad5e2b67d  (location_id,academic_year,programme_id,year_group) UNIQUE
#  idx_on_location_year_group_id_programme_id_405f51181e           (location_year_group_id,programme_id) UNIQUE
#  index_location_programme_year_groups_on_location_year_group_id  (location_year_group_id)
#  index_location_programme_year_groups_on_programme_id            (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id) ON DELETE => cascade
#  fk_rails_...  (location_year_group_id => location_year_groups.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#
describe Location::ProgrammeYearGroup do
  subject(:location_programme_year_group) do
    build(:location_programme_year_group, location:)
  end

  let(:location) { create(:school) }

  describe "associations" do
    it { should belong_to(:location) }
    it { should belong_to(:programme) }
  end

  describe "validations" do
    it "validates year group is suitable for the location" do
      expect(location_programme_year_group).to validate_inclusion_of(
        :year_group
      ).in_array(location.gias_year_groups)
    end
  end
end
