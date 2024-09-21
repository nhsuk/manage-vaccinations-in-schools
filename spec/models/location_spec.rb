# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id               :bigint           not null, primary key
#  address_line_1   :text
#  address_line_2   :text
#  address_postcode :text
#  address_town     :text
#  name             :text             not null
#  ods_code         :string
#  type             :integer          not null
#  url              :text
#  urn              :string
#  year_groups      :integer          default([]), not null, is an Array
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  team_id          :bigint
#
# Indexes
#
#  index_locations_on_ods_code  (ods_code) UNIQUE
#  index_locations_on_team_id   (team_id)
#  index_locations_on_urn       (urn) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

describe Location do
  describe "scopes" do
    describe "#for_programme" do
      subject(:for_programme) { described_class.for_programme(programme) }

      let(:team) { create(:team) }
      let(:programme) { create(:programme, :hpv, team:) } # 8-11
      let(:matching) { create(:location, :secondary, team:) } # 7-11
      let(:mismatch_year_group) { create(:location, :primary, team:) } # 0-6
      let(:mismatch_team) { create(:location, :secondary) }

      it { should include(matching) }
      it { should_not include(mismatch_year_group) }
      it { should_not include(mismatch_team) }
    end
  end

  describe "validations" do
    it { should validate_presence_of(:name) }

    context "with a generic clinic" do
      subject(:location) { build(:location, :generic_clinic, ods_code: "abc") }

      it { should validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code) }

      it { should_not validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end

    context "with a school" do
      subject(:location) { build(:location, :school, urn: "abc") }

      it { should_not validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code) }

      it { should validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end
  end
end
