# frozen_string_literal: true

# == Schema Information
#
# Table name: location_programme_year_groups
#
#  id                     :bigint           not null, primary key
#  programme_type         :enum             not null
#  location_year_group_id :bigint           not null
#  programme_id           :bigint
#
# Indexes
#
#  idx_on_location_year_group_id_programme_type_904fa3b284         (location_year_group_id,programme_type) UNIQUE
#  index_location_programme_year_groups_on_location_year_group_id  (location_year_group_id)
#  index_location_programme_year_groups_on_programme_type          (programme_type)
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
