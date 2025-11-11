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
#  gias_year_groups          :integer          default([]), not null, is an Array
#  name                      :text             not null
#  ods_code                  :string
#  site                      :string
#  status                    :integer          default("unknown"), not null
#  systm_one_code            :string
#  type                      :integer          not null
#  url                       :text
#  urn                       :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  subteam_id                :bigint
#
# Indexes
#
#  index_locations_on_ods_code        (ods_code) UNIQUE
#  index_locations_on_subteam_id      (subteam_id)
#  index_locations_on_systm_one_code  (systm_one_code) UNIQUE
#  index_locations_on_urn             (urn) UNIQUE WHERE (site IS NULL)
#  index_locations_on_urn_and_site    (urn,site) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (subteam_id => subteams.id)
#

describe Location do
  subject(:location) { build(:location) }

  describe "associations" do
    it { should have_many(:location_programme_year_groups) }

    describe "local_authority" do
      context "when the location has a gias_local_authority_code" do
        let!(:local_authority) { create(:local_authority, gias_code: 111) }

        before do
          create(:local_authority, gias_code: 222)
          location.gias_local_authority_code = local_authority.gias_code
        end

        it "returns the local_authority with that code" do
          expect(location.local_authority).to eq(local_authority)
        end
      end
    end
  end

  describe "scopes" do
    describe "#find_by_urn_and_site" do
      subject(:scope) { described_class.find_by_urn_and_site(urn_and_site) }

      let(:location_without_site) { create(:school, urn: "123456") }
      let(:location_with_site) { create(:school, urn: "123456", site: "A") }

      context "with just a URN" do
        let(:urn_and_site) { "123456" }

        it { should eq(location_without_site) }
      end

      context "with a URN and a site" do
        let(:urn_and_site) { "123456A" }

        it { should eq(location_with_site) }
      end
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
          [team.organisation.ods_code]
        )
      end

      it { should_not validate_presence_of(:urn) }
      it { should validate_uniqueness_of(:urn) }
      it { should validate_uniqueness_of(:site).scoped_to(:urn) }
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
          "gias_year_groups" => [],
          "id" => location.id,
          "is_attached_to_team" => false,
          "name" => location.name,
          "ods_code" => location.ods_code,
          "site" => location.site,
          "status" => "unknown",
          "type" => "community_clinic",
          "url" => location.url,
          "urn" => nil
        }
      )
    end

    context "when the location is not attached to a team" do
      let(:location) { create(:school, subteam: nil) }

      it { should include("is_attached_to_team" => false) }
    end
  end

  describe "#import_default_programme_year_groups!" do
    subject(:import_default_programme_year_groups!) do
      location.import_default_programme_year_groups!(programmes, academic_year:)
    end

    let(:programmes) { [CachedProgramme.flu] } # years 0 to 11
    let(:academic_year) { AcademicYear.pending }

    context "when the location has no year groups" do
      let(:location) { create(:school, gias_year_groups: []) }

      it "doesn't create any programme year groups" do
        expect { import_default_programme_year_groups! }.not_to change(
          location.location_programme_year_groups,
          :count
        )
      end
    end

    context "when the location has fewer year groups than the default" do
      let(:location) { create(:school, gias_year_groups: (0..3).to_a) }

      it "creates only suitable year groups" do
        expect { import_default_programme_year_groups! }.to change(
          location.location_programme_year_groups,
          :count
        ).by(4)

        expect(location.location_programme_year_groups.pluck_year_groups).to eq(
          (0..3).to_a
        )
      end
    end

    context "when the location has more year groups than the default" do
      let(:location) { create(:school, gias_year_groups: (-1..14).to_a) }

      it "creates only suitable year groups" do
        expect { import_default_programme_year_groups! }.to change(
          location.location_programme_year_groups,
          :count
        ).by(12)

        expect(location.location_programme_year_groups.pluck_year_groups).to eq(
          (0..11).to_a
        )
      end
    end
  end
end
