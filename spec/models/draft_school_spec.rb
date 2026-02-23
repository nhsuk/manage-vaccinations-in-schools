# frozen_string_literal: true

describe DraftSchool do
  subject(:draft_school) do
    described_class.new(request_session:, current_user:, **attributes)
  end

  let(:team) { create(:team, :with_one_nurse) }
  let(:current_user) { team.users.first }
  let(:request_session) { {} }

  let(:school) { create(:school, :secondary, team:) }

  let(:valid_attributes) do
    {
      parent_urn_and_site: school.urn_and_site,
      name: "New Site Name",
      address_line_1: "123 Main Street",
      address_line_2: "Floor 2",
      address_town: "London",
      address_postcode: "SW1A 1AA"
    }
  end

  describe "validations" do
    context "on the school step" do
      let(:attributes) { { wizard_step: :school } }

      it { should validate_presence_of(:parent_urn_and_site).on(:update) }

      context "with valid urn_and_site" do
        let(:attributes) do
          { wizard_step: :school, parent_urn_and_site: school.urn_and_site }
        end

        it { should be_valid(:update) }
      end
    end

    context "on the details step" do
      let(:attributes) { valid_attributes.merge(wizard_step: :details) }

      it { should validate_presence_of(:name).on(:update) }
      it { should validate_presence_of(:address_line_1).on(:update) }
      it { should validate_presence_of(:address_town).on(:update) }
      it { should validate_presence_of(:address_postcode).on(:update) }

      context "with valid attributes" do
        it { should be_valid(:update) }
      end

      context "with a duplicate name" do
        let(:attributes) do
          valid_attributes.merge(wizard_step: :details, name: school.name)
        end

        it "is invalid" do
          expect(draft_school).not_to be_valid(:update)
          expect(draft_school.errors[:name]).to include(
            "This site name is already in use. Enter a different name."
          )
        end
      end

      context "with an invalid postcode" do
        let(:attributes) do
          valid_attributes.merge(
            wizard_step: :details,
            address_postcode: "invalid"
          )
        end

        it { should_not be_valid(:update) }
      end

      context "without address_line_2" do
        let(:attributes) do
          valid_attributes.merge(wizard_step: :details, address_line_2: nil)
        end

        it { should be_valid(:update) }
      end

      context "with invalid characters in name" do
        let(:attributes) do
          valid_attributes.merge(wizard_step: :details, name: "School with []")
        end

        it "is invalid" do
          expect(draft_school).not_to be_valid(:update)
          expect(draft_school.errors[:name]).to include(
            "includes invalid character(s)"
          )
        end
      end

      context "with valid special characters in name" do
        [
          "St Mary's & St John's",
          "École Française",
          "Smith-Jones School",
          "St. Mary's School, (Site A)"
        ].each do |valid_name|
          context "with name '#{valid_name}'" do
            let(:attributes) do
              valid_attributes.merge(wizard_step: :details, name: valid_name)
            end

            it { should be_valid(:update) }
          end
        end
      end
    end

    context "on the confirm step" do
      let(:attributes) { valid_attributes.merge(wizard_step: :confirm) }

      it { should be_valid(:update) }
    end
  end

  describe "#wizard_steps" do
    let(:attributes) { {} }

    it "returns the correct steps" do
      expect(draft_school.wizard_steps).to eq(%i[school details confirm])
    end
  end

  describe "#parent_school" do
    context "when urn_and_site is nil" do
      let(:attributes) { { parent_urn_and_site: nil } }

      it { expect(draft_school.parent_school).to be_nil }
    end

    context "when urn_and_site is set" do
      let(:attributes) { { parent_urn_and_site: school.urn_and_site } }

      it { expect(draft_school.parent_school).to eq(school) }
    end

    context "when urn_and_site does not match any school" do
      let(:attributes) { { parent_urn_and_site: "999999" } }

      it { expect(draft_school.parent_school).to be_nil }
    end

    context "when school belongs to a different team" do
      let(:other_team) { create(:team) }
      let(:other_school) { create(:school, :secondary, team: other_team) }
      let(:attributes) { { parent_urn_and_site: other_school.urn_and_site } }

      it { expect(draft_school.parent_school).to be_nil }
    end
  end

  describe "#existing_names" do
    context "when urn_and_site is blank" do
      let(:attributes) { { parent_urn_and_site: nil } }

      it { expect(draft_school.existing_names).to eq([]) }
    end

    context "when urn_and_site is set" do
      let(:attributes) { { parent_urn_and_site: school.urn_and_site } }

      it "returns names of schools with the same URN" do
        expect(draft_school.existing_names).to include(school.name)
      end
    end

    context "when multiple sites exist with the same URN" do
      before do
        create(
          :school,
          :secondary,
          urn: school.urn,
          site: "A",
          name: "School Site A"
        )
        create(
          :school,
          :secondary,
          urn: school.urn,
          site: "B",
          name: "School Site B"
        )
      end

      let(:attributes) { { parent_urn_and_site: school.urn_and_site } }

      it "returns all site names" do
        expect(draft_school.existing_names).to include(
          school.name,
          "School Site A",
          "School Site B"
        )
      end
    end
  end

  describe "#request_session_key" do
    let(:attributes) { {} }

    it { expect(draft_school.request_session_key).to eq("draft_school") }
  end

  describe "#address_parts" do
    context "with all address fields" do
      let(:attributes) { valid_attributes }

      it "returns all address parts" do
        expect(draft_school.address_parts).to eq(
          ["123 Main Street", "Floor 2", "London", "SW1A 1AA"]
        )
      end
    end

    context "with some blank fields" do
      let(:attributes) do
        valid_attributes.merge(address_line_2: nil, address_town: "")
      end

      it "excludes blank fields" do
        expect(draft_school.address_parts).to eq(
          ["123 Main Street", "SW1A 1AA"]
        )
      end
    end

    context "with no address fields" do
      let(:attributes) { {} }

      it { expect(draft_school.address_parts).to eq([]) }
    end
  end

  describe "normalization" do
    let(:attributes) { valid_attributes.merge(wizard_step: :details) }

    it "normalises whitespace in name" do
      draft_school.name = "  School   Name  "
      draft_school.valid?(:update)
      expect(draft_school.name).to eq("School Name")
    end

    it "removes zero-width joiners from name" do
      draft_school.name = "School\u200DName"
      draft_school.valid?(:update)
      expect(draft_school.name).to eq("SchoolName")
    end

    it "removes non-breaking spaces from name" do
      draft_school.name = "School\u00A0Name"
      draft_school.valid?(:update)
      expect(draft_school.name).to eq("School Name")
    end

    it "normalises whitespace in address_line_1" do
      draft_school.address_line_1 = "  123   Main   Street  "
      draft_school.valid?(:update)
      expect(draft_school.address_line_1).to eq("123 Main Street")
    end

    it "removes zero-width joiners from address_line_1" do
      draft_school.address_line_1 = "123\u200DMain\u200DStreet"
      draft_school.valid?(:update)
      expect(draft_school.address_line_1).to eq("123MainStreet")
    end

    it "normalises whitespace in address_line_2" do
      draft_school.address_line_2 = "  Floor   2  "
      draft_school.valid?(:update)
      expect(draft_school.address_line_2).to eq("Floor 2")
    end

    it "normalises whitespace in address_town" do
      draft_school.address_town = "  Greater   London  "
      draft_school.valid?(:update)
      expect(draft_school.address_town).to eq("Greater London")
    end

    it "returns nil for blank values after normalization" do
      draft_school.address_line_2 = "   "
      draft_school.valid?(:update)
      expect(draft_school.address_line_2).to be_nil
    end
  end

  describe "session persistence" do
    let(:attributes) { valid_attributes }

    it "persists to session on save" do
      draft_school.save!
      expect(request_session["draft_school"]).to eq(
        {
          "address_line_1" => "123 Main Street",
          "address_line_2" => "Floor 2",
          "address_postcode" => "SW1A 1AA",
          "address_town" => "London",
          "editing_id" => nil,
          "name" => "New Site Name",
          "parent_urn_and_site" => school.urn_and_site
        }
      )
    end

    it "clears session on clear!" do
      draft_school.save!
      draft_school.clear!
      expect(request_session["draft_school"]).to eq(
        {
          "address_line_1" => nil,
          "address_line_2" => nil,
          "address_postcode" => nil,
          "address_town" => nil,
          "editing_id" => nil,
          "name" => nil,
          "parent_urn_and_site" => nil
        }
      )
    end
  end

  describe "#urn_and_site" do
    context "when creating a new site" do
      let(:attributes) { valid_attributes }

      it "returns the URN with the next site letter" do
        expect(draft_school.urn_and_site).to eq("#{school.urn}B")
      end

      context "when sites already exist" do
        before do
          create(:school, urn: school.urn, site: "A", name: "Site A")
          create(:school, urn: school.urn, site: "B", name: "Site B")
        end

        it "returns the URN with the next available site letter" do
          expect(draft_school.urn_and_site).to eq("#{school.urn}C")
        end
      end
    end
  end

  describe "#source_location" do
    context "when creating a new site" do
      let(:attributes) { valid_attributes }

      it "returns the parent school" do
        expect(draft_school.source_location).to eq(school)
      end
    end
  end
end
