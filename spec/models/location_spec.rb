# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id                        :bigint           not null, primary key
#  address_line_1            :text
#  address_line_2            :text
#  address_postcode          :text
#  address_town              :text
#  gias_establishment_number :integer
#  gias_local_authority_code :integer
#  name                      :text             not null
#  ods_code                  :string
#  type                      :integer          not null
#  url                       :text
#  urn                       :string
#  year_groups               :integer          default([]), not null, is an Array
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  team_id                   :bigint
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
  describe "validations" do
    it { should validate_presence_of(:name) }

    context "with a community clinic" do
      subject(:location) { build(:community_clinic, organisation:) }

      let(:organisation) { create(:organisation) }

      it { should_not validate_presence_of(:gias_establishment_number) }
      it { should_not validate_presence_of(:gias_local_authority_code) }

      it { should_not validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }

      it do
        expect(location).to validate_exclusion_of(:ods_code).in_array(
          [organisation.ods_code]
        )
      end

      it { should_not validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end

    context "with a generic clinic" do
      subject(:location) { build(:generic_clinic, organisation:) }

      let(:organisation) { create(:organisation) }

      it { should_not validate_presence_of(:gias_establishment_number) }
      it { should_not validate_presence_of(:gias_local_authority_code) }

      it { should_not validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }

      it do
        expect(location).to validate_inclusion_of(:ods_code).in_array(
          [organisation.ods_code]
        )
      end

      it { should_not validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end

    context "with a GP practice" do
      subject(:location) { build(:gp_practice, ods_code: "abc") }

      it { should_not validate_presence_of(:gias_establishment_number) }
      it { should_not validate_presence_of(:gias_local_authority_code) }

      it { should validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }

      it { should_not validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end

    context "with a school" do
      subject(:location) { build(:school, urn: "abc") }

      it { should validate_presence_of(:gias_establishment_number) }
      it { should validate_presence_of(:gias_local_authority_code) }

      it { should_not validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }

      it { should validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end
  end

  it { should normalize(:address_postcode).from(" SW111AA ").to("SW11 1AA") }
  it { should normalize(:ods_code).from(" r1a ").to("R1A") }
  it { should normalize(:urn).from(" 123 ").to("123") }

  describe "#clinic?" do
    subject(:clinic?) { location.clinic? }

    context "with a community clinic" do
      let(:location) { build(:community_clinic) }

      it { should be(true) }
    end

    context "with a generic clinic" do
      let(:location) { build(:generic_clinic) }

      it { should be(true) }
    end

    context "with a school" do
      let(:location) { build(:school) }

      it { should be(false) }
    end
  end

  describe "#dfe_number" do
    subject(:dfe_number) { location.dfe_number }

    context "with a community clinic" do
      let(:location) { build(:community_clinic) }

      it { should be_nil }
    end

    context "with a generic clinic" do
      let(:location) { build(:generic_clinic) }

      it { should be_nil }
    end

    context "with a school" do
      let(:location) do
        build(
          :school,
          gias_local_authority_code: 123,
          gias_establishment_number: 456
        )
      end

      it { should eq("123456") }
    end
  end
end
