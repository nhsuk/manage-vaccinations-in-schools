# frozen_string_literal: true

describe Onboarding do
  subject(:onboarding) { described_class.new(config) }

  let(:config) { YAML.safe_load(file_fixture(filename).read) }

  let!(:programme) { create(:programme, :hpv) }
  # rubocop:disable RSpec/IndexedLet
  let!(:school1) { create(:school, :secondary, :open, urn: "123456") }
  let!(:school2) { create(:school, :secondary, :open, urn: "234567") }
  let!(:school3) { create(:school, :secondary, :open, urn: "345678") }
  let!(:school4) { create(:school, :secondary, :open, urn: "456789") }
  # rubocop:enable RSpec/IndexedLet

  before { create(:school, :secondary, :closed, urn: "567890") }

  context "with a valid configuration file" do
    let(:filename) { "onboarding/valid.yaml" }

    it { should be_valid }

    it "set up the models" do
      expect { onboarding.save! }.not_to raise_error

      organisation = Organisation.find_by!(ods_code: "EXAMPLE")
      expect(organisation.name).to eq("NHS Trust")
      expect(organisation.email).to eq("example@trust.nhs.uk")
      expect(organisation.phone).to eq("07700 900815")
      expect(organisation.phone_instructions).to eq(
        "option 1, followed by option 3"
      )
      expect(organisation.careplus_venue_code).to eq("EXAMPLE")
      expect(organisation.programmes).to contain_exactly(programme)

      expect(organisation.locations.generic_clinic.count).to eq(1)
      generic_clinic = organisation.locations.generic_clinic.first
      expect(generic_clinic.year_groups).to eq([8, 9, 10, 11])
      expect(generic_clinic.programme_year_groups.count).to eq(4)

      subteam1 =
        organisation.subteams.includes(:schools).find_by!(name: "Subteam 1")
      expect(subteam1.email).to eq("subteam-1@trust.nhs.uk")
      expect(subteam1.phone).to eq("07700 900816")
      expect(subteam1.phone_instructions).to eq("option 9")
      expect(subteam1.reply_to_id).to eq("24af66c3-d6bd-4b9f-8067-3844f49e08d0")

      subteam2 =
        organisation.subteams.includes(:schools).find_by!(name: "Subteam 2")
      expect(subteam2.email).to eq("subteam-2@trust.nhs.uk")
      expect(subteam2.phone).to eq("07700 900817")
      expect(subteam2.reply_to_id).to be_nil

      expect(subteam1.schools).to contain_exactly(school1, school2)
      expect(subteam2.schools).to contain_exactly(school3, school4)

      expect(school1.programme_year_groups.count).to eq(4)
      expect(school2.programme_year_groups.count).to eq(4)
      expect(school3.programme_year_groups.count).to eq(4)
      expect(school4.programme_year_groups.count).to eq(4)

      clinic1 = subteam1.community_clinics.find_by!(ods_code: nil)
      expect(clinic1.name).to eq("10 Downing Street")
      expect(clinic1.address_postcode).to eq("SW1A 1AA")

      clinic2 = subteam2.community_clinics.find_by!(ods_code: "SW1A11")
      expect(clinic2.name).to eq("11 Downing Street")
      expect(clinic2.address_postcode).to eq("SW1A 1AA")

      expect(organisation.sessions.count).to eq(5)
    end
  end

  context "with an invalid configuration file" do
    let(:filename) { "onboarding/invalid.yaml" }

    it { should be_invalid }

    it "has errors" do
      onboarding.invalid?

      expect(onboarding.errors.messages).to eq(
        {
          "organisation.careplus_venue_code": ["can't be blank"],
          "organisation.name": ["can't be blank"],
          "organisation.ods_code": ["can't be blank"],
          "organisation.phone": ["can't be blank", "is invalid"],
          "organisation.privacy_notice_url": ["can't be blank"],
          "organisation.privacy_policy_url": ["can't be blank"],
          "school.0.subteam": ["can't be blank"],
          "school.1.subteam": ["can't be blank"],
          "school.2.status": ["is not included in the list"],
          "subteam.email": ["can't be blank"],
          "subteam.name": ["can't be blank"],
          clinics: ["can't be blank"],
          programmes: ["can't be blank"]
        }
      )
    end
  end
end
