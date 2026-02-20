# frozen_string_literal: true

describe DraftSchool do
  subject(:draft_school) do
    described_class.new(
      request_session:,
      current_user:,
      current_team:,
      **attributes
    )
  end

  let(:team) { create(:team, :with_one_nurse) }
  let(:current_user) { team.users.first }
  let(:current_team) { team }
  let(:request_session) { {} }

  let(:school) { create(:school, :secondary, urn: "123456") }
  let(:academic_year) { AcademicYear.pending }

  describe "validations" do
    context "on the urn step" do
      let(:attributes) { { wizard_step: :urn } }

      it { should validate_presence_of(:urn).on(:update) }

      context "with valid urn" do
        let(:attributes) { { wizard_step: :urn, urn: school.urn } }

        it { should be_valid(:update) }
      end

      context "when school does not exist" do
        let(:attributes) { { wizard_step: :urn, urn: "999999" } }

        it "is invalid" do
          expect(draft_school).not_to be_valid(:update)
          expect(draft_school.errors[:urn]).to include(
            "No school found with this URN"
          )
        end
      end

      context "when school is closed" do
        let(:closed_school) { create(:school, :closed, urn: "111111") }
        let(:attributes) { { wizard_step: :urn, urn: closed_school.urn } }

        it "is invalid" do
          expect(draft_school).not_to be_valid(:update)
          expect(draft_school.errors[:urn]).to include(
            "This school is closed and cannot be assigned"
          )
        end
      end

      context "when school is already assigned to current team" do
        before do
          create(
            :team_location,
            team: current_team,
            location: school,
            academic_year:
          )
        end

        let(:attributes) { { wizard_step: :urn, urn: school.urn } }

        it "is invalid" do
          expect(draft_school).not_to be_valid(:update)
          expect(draft_school.errors[:urn]).to include(
            "This school or its sites are already assigned to your team"
          )
        end
      end

      context "when school is assigned to a different team" do
        let(:other_team) { create(:team) }
        let(:attributes) { { wizard_step: :urn, urn: school.urn } }

        before do
          create(
            :team_location,
            team: other_team,
            location: school,
            academic_year:
          )
        end

        it "is invalid" do
          expect(draft_school).not_to be_valid(:update)
          expect(draft_school.errors[:urn]).to include(
            "This school is already assigned to a different team"
          )
        end
      end

      context "when school has sites and sites are assigned to current team" do
        let(:school_with_sites) { create(:school, :secondary, urn: "222222") }
        let(:attributes) { { wizard_step: :urn, urn: school_with_sites.urn } }
        let(:site) do
          create(
            :school,
            :secondary,
            urn: school_with_sites.urn,
            site: "A",
            name: "School Site A"
          )
        end

        before do
          create(
            :team_location,
            team: current_team,
            location: site,
            academic_year:
          )
        end

        it "is invalid" do
          expect(draft_school).not_to be_valid(:update)
          expect(draft_school.errors[:urn]).to include(
            "This school or its sites are already assigned to your team"
          )
        end
      end
    end

    context "on the confirm step" do
      let(:attributes) { { wizard_step: :confirm, urn: school.urn } }

      it do
        expect(draft_school).to validate_presence_of(:confirm_school).on(
          :update
        ).with_message("Select yes if this is the correct school")
      end

      context "with confirm_school set" do
        let(:attributes) do
          { wizard_step: :confirm, urn: school.urn, confirm_school: "yes" }
        end

        it { should be_valid(:update) }
      end
    end
  end

  describe "#wizard_steps" do
    let(:attributes) { {} }

    it "returns the correct steps" do
      expect(draft_school.wizard_steps).to eq(%i[urn confirm])
    end
  end

  describe "#school" do
    context "when urn is nil" do
      let(:attributes) { { urn: nil } }

      it { expect(draft_school.school).to be_nil }
    end

    context "when urn is blank" do
      let(:attributes) { { urn: "" } }

      it { expect(draft_school.school).to be_nil }
    end

    context "when urn is set" do
      let(:attributes) { { urn: school.urn } }

      it { expect(draft_school.school).to eq(school) }
    end

    context "when urn has whitespace" do
      let(:attributes) { { urn: "  #{school.urn}  " } }

      it "strips whitespace and finds the school" do
        expect(draft_school.school).to eq(school)
      end
    end

    context "when urn does not match any school" do
      let(:attributes) { { urn: "999999" } }

      it { expect(draft_school.school).to be_nil }
    end
  end

  describe "#schools_to_add" do
    context "when school is nil" do
      let(:attributes) { { urn: nil } }

      it { expect(draft_school.schools_to_add).to eq([]) }
    end

    context "when school has no sites" do
      let(:attributes) { { urn: school.urn } }

      it "returns the school" do
        expect(draft_school.schools_to_add).to eq([school])
      end
    end

    context "when school has multiple sites" do
      let(:school_with_sites) { create(:school, :secondary, urn: "333333") }
      let!(:site_a) do
        create(
          :school,
          :secondary,
          urn: school_with_sites.urn,
          site: "A",
          name: "School Site A"
        )
      end
      let!(:site_b) do
        create(
          :school,
          :secondary,
          urn: school_with_sites.urn,
          site: "B",
          name: "School Site B"
        )
      end

      let(:attributes) { { urn: school_with_sites.urn } }

      it "returns only the sites (not the main school)" do
        expect(draft_school.schools_to_add).to contain_exactly(site_a, site_b)
        expect(draft_school.schools_to_add).not_to include(school_with_sites)
      end
    end
  end

  describe "#request_session_key" do
    let(:attributes) { {} }

    it { expect(draft_school.request_session_key).to eq("draft_school") }
  end

  describe "#address_parts" do
    let(:attributes) { { urn: school.urn } }

    before do
      school.update!(
        address_line_1: "123 Main Street",
        address_line_2: "Floor 2",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )
    end

    context "with all address fields" do
      it "returns all address parts" do
        expect(draft_school.address_parts).to eq(
          ["123 Main Street", "Floor 2", "London", "SW1A 1AA"]
        )
      end
    end

    context "with some blank fields" do
      before { school.update!(address_line_2: nil, address_town: "") }

      it "excludes blank fields" do
        expect(draft_school.address_parts).to eq(
          ["123 Main Street", "SW1A 1AA"]
        )
      end
    end
  end
end
