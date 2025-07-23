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
#  status                    :integer          default("unknown"), not null
#  type                      :integer          not null
#  url                       :text
#  urn                       :string
#  year_groups               :integer          default([]), not null, is an Array
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  subteam_id                :bigint
#
# Indexes
#
#  index_locations_on_ods_code    (ods_code) UNIQUE
#  index_locations_on_subteam_id  (subteam_id)
#  index_locations_on_urn         (urn) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (subteam_id => subteams.id)
#

describe Location do
  subject(:location) { build(:location) }

  describe "associations" do
    it do
      expect(location).to have_many(:programmes).through(
        :programme_year_groups
      ).order(:type)
    end
  end

  describe "validations" do
    it { should validate_presence_of(:name) }

    context "with a community clinic" do
      subject(:location) { build(:community_clinic, team:) }

      let(:team) { create(:team) }

      it { should_not validate_presence_of(:gias_establishment_number) }
      it { should_not validate_presence_of(:gias_local_authority_code) }

      it { should_not validate_presence_of(:ods_code) }
      it { should validate_uniqueness_of(:ods_code).ignoring_case_sensitivity }

      it do
        expect(location).to validate_exclusion_of(:ods_code).in_array(
          [team.ods_code]
        )
      end

      it { should_not validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
    end

    context "with a generic clinic" do
      subject(:location) { build(:generic_clinic, team:) }

      let(:team) { create(:team) }

      it { should_not validate_presence_of(:gias_establishment_number) }
      it { should_not validate_presence_of(:gias_local_authority_code) }

      it { should validate_absence_of(:ods_code) }

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

  describe "#as_json" do
    subject(:as_json) { location.as_json }

    let(:location) { create(:community_clinic) }

    it do
      expect(as_json).to eq(
        {
          "address_line_1" => location.address_line_1,
          "address_line_2" => location.address_line_2,
          "address_postcode" => location.address_postcode,
          "address_town" => location.address_town,
          "gias_establishment_number" => nil,
          "gias_local_authority_code" => nil,
          "id" => location.id,
          "is_attached_to_team" => false,
          "name" => location.name,
          "ods_code" => location.ods_code,
          "status" => "unknown",
          "type" => "community_clinic",
          "url" => location.url,
          "urn" => nil,
          "year_groups" => []
        }
      )
    end

    context "when the location is not attached to a team" do
      let(:location) { create(:school, subteam: nil) }

      it { should include("is_attached_to_team" => false) }
    end
  end

  describe "#create_default_programme_year_groups!" do
    subject(:create_default_programme_year_groups!) do
      location.create_default_programme_year_groups!(programmes)
    end

    let(:programmes) { [create(:programme, :flu)] } # years 0 to 11

    context "when the location has no year groups" do
      let(:location) { create(:school, year_groups: []) }

      it "doesn't create any programme year groups" do
        expect { create_default_programme_year_groups! }.not_to change(
          location.programme_year_groups,
          :count
        )
      end
    end

    context "when the location has fewer year groups than the default" do
      let(:location) { create(:school, year_groups: (0..3).to_a) }

      it "creates only suitable year groups" do
        expect { create_default_programme_year_groups! }.to change(
          location.programme_year_groups,
          :count
        ).by(4)

        expect(location.programme_year_groups.pluck(:year_group).sort).to eq(
          (0..3).to_a
        )
      end
    end

    context "when the location has more year groups than the default" do
      let(:location) { create(:school, year_groups: (-1..14).to_a) }

      it "creates only suitable year groups" do
        expect { create_default_programme_year_groups! }.to change(
          location.programme_year_groups,
          :count
        ).by(12)

        expect(location.programme_year_groups.pluck(:year_group).sort).to eq(
          (0..11).to_a
        )
      end
    end
  end
end
