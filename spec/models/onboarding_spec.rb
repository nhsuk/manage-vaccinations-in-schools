# frozen_string_literal: true

describe Onboarding do
  subject(:onboarding) { described_class.new(config) }

  let(:config) { YAML.safe_load(file_fixture(filename).read) }

  let!(:programme) { create(:programme, :hpv) }
  # rubocop:disable RSpec/IndexedLet
  let!(:school1) { create(:location, :secondary, urn: "123456") }
  let!(:school2) { create(:location, :secondary, urn: "234567") }
  let!(:school3) { create(:location, :secondary, urn: "345678") }
  let!(:school4) { create(:location, :secondary, urn: "456789") }
  # rubocop:enable RSpec/IndexedLet

  context "with a valid configuration file" do
    let(:filename) { "onboarding/valid.yaml" }

    it { should be_valid }

    it "set up the models" do
      expect { onboarding.save! }.not_to raise_error

      organisation = Organisation.find_by!(ods_code: "EXAMPLE")
      expect(organisation.name).to eq("NHS Trust")
      expect(organisation.email).to eq("example@trust.nhs.uk")
      expect(organisation.phone).to eq("07700 900815")
      expect(organisation.programmes).to contain_exactly(programme)

      team1 = organisation.teams.find_by!(name: "Team 1")
      expect(team1.email).to eq("team-1@trust.nhs.uk")
      expect(team1.phone).to eq("07700 900816")

      team2 = organisation.teams.find_by!(name: "Team 2")
      expect(team2.email).to eq("team-2@trust.nhs.uk")
      expect(team2.phone).to eq("07700 900817")

      expect(team1.schools).to contain_exactly(school1, school2)
      expect(team2.schools).to contain_exactly(school3, school4)

      clinic1 = team1.community_clinics.find_by!(ods_code: "SW1A10")
      expect(clinic1.name).to eq("10 Downing Street")
      expect(clinic1.address_postcode).to eq("SW1A 1AA")

      clinic2 = team2.community_clinics.find_by!(ods_code: "SW1A11")
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
          "organisation.name": ["can't be blank"],
          "organisation.ods_code": ["can't be blank"],
          "organisation.phone": ["can't be blank", "is invalid"],
          "school.0.team": ["can't be blank"],
          "school.1.team": ["can't be blank"],
          "team.email": ["can't be blank"],
          "team.name": ["can't be blank"],
          clinics: ["can't be blank"],
          programmes: ["can't be blank"]
        }
      )
    end
  end
end
