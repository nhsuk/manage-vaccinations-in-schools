# frozen_string_literal: true

describe DraftSchoolSite do
  subject(:draft_school_site) do
    described_class.new(request_session:, current_user:, **attributes)
  end

  let(:team) { create(:team, :with_one_nurse) }
  let(:current_user) { team.users.first }
  let(:request_session) { {} }

  let(:school) { create(:school, :secondary, team:) }

  let(:valid_attributes) do
    {
      urn: school.urn,
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

      it { should validate_presence_of(:urn).on(:update) }

      context "with valid urn" do
        let(:attributes) { { wizard_step: :school, urn: school.urn } }

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
          expect(draft_school_site).not_to be_valid(:update)
          expect(draft_school_site.errors[:name]).to include(
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
          expect(draft_school_site).not_to be_valid(:update)
          expect(draft_school_site.errors[:name]).to include(
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
      expect(draft_school_site.wizard_steps).to eq(%i[school details confirm])
    end
  end

  describe "#parent_school" do
    context "when urn is nil" do
      let(:attributes) { { urn: nil } }

      it { expect(draft_school_site.parent_school).to be_nil }
    end

    context "when urn is set" do
      let(:attributes) { { urn: school.urn } }

      it { expect(draft_school_site.parent_school).to eq(school) }
    end

    context "when urn does not match any school" do
      let(:attributes) { { urn: "999999" } }

      it { expect(draft_school_site.parent_school).to be_nil }
    end

    context "when school belongs to a different team" do
      let(:other_team) { create(:team) }
      let(:other_school) { create(:school, :secondary, team: other_team) }
      let(:attributes) { { urn: other_school.urn } }

      it { expect(draft_school_site.parent_school).to be_nil }
    end
  end

  describe "#existing_names" do
    context "when urn is blank" do
      let(:attributes) { { urn: nil } }

      it { expect(draft_school_site.existing_names).to eq([]) }
    end

    context "when urn is set" do
      let(:attributes) { { urn: school.urn } }

      it "returns names of schools with the same URN" do
        expect(draft_school_site.existing_names).to include(school.name)
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

      let(:attributes) { { urn: school.urn } }

      it "returns all site names" do
        expect(draft_school_site.existing_names).to include(
          school.name,
          "School Site A",
          "School Site B"
        )
      end
    end
  end

  describe "#request_session_key" do
    let(:attributes) { {} }

    it { expect(draft_school_site.request_session_key).to eq("draft_school") }
  end

  describe "#address_parts" do
    context "with all address fields" do
      let(:attributes) { valid_attributes }

      it "returns all address parts" do
        expect(draft_school_site.address_parts).to eq(
          ["123 Main Street", "Floor 2", "London", "SW1A 1AA"]
        )
      end
    end

    context "with some blank fields" do
      let(:attributes) do
        valid_attributes.merge(address_line_2: nil, address_town: "")
      end

      it "excludes blank fields" do
        expect(draft_school_site.address_parts).to eq(
          ["123 Main Street", "SW1A 1AA"]
        )
      end
    end

    context "with no address fields" do
      let(:attributes) { {} }

      it { expect(draft_school_site.address_parts).to eq([]) }
    end
  end

  describe "normalization" do
    let(:attributes) { valid_attributes.merge(wizard_step: :details) }

    it "normalizes whitespace in name" do
      draft_school_site.name = "  School   Name  "
      draft_school_site.valid?(:update)
      expect(draft_school_site.name).to eq("School Name")
    end

    it "removes zero-width joiners from name" do
      draft_school_site.name = "School\u200DName"
      draft_school_site.valid?(:update)
      expect(draft_school_site.name).to eq("SchoolName")
    end

    it "removes non-breaking spaces from name" do
      draft_school_site.name = "School\u00A0Name"
      draft_school_site.valid?(:update)
      expect(draft_school_site.name).to eq("School Name")
    end

    it "normalizes whitespace in address_line_1" do
      draft_school_site.address_line_1 = "  123   Main   Street  "
      draft_school_site.valid?(:update)
      expect(draft_school_site.address_line_1).to eq("123 Main Street")
    end

    it "removes zero-width joiners from address_line_1" do
      draft_school_site.address_line_1 = "123\u200DMain\u200DStreet"
      draft_school_site.valid?(:update)
      expect(draft_school_site.address_line_1).to eq("123MainStreet")
    end

    it "normalizes whitespace in address_line_2" do
      draft_school_site.address_line_2 = "  Floor   2  "
      draft_school_site.valid?(:update)
      expect(draft_school_site.address_line_2).to eq("Floor 2")
    end

    it "normalizes whitespace in address_town" do
      draft_school_site.address_town = "  Greater   London  "
      draft_school_site.valid?(:update)
      expect(draft_school_site.address_town).to eq("Greater London")
    end

    it "returns nil for blank values after normalization" do
      draft_school_site.address_line_2 = "   "
      draft_school_site.valid?(:update)
      expect(draft_school_site.address_line_2).to be_nil
    end
  end

  describe "session persistence" do
    let(:attributes) { valid_attributes }

    it "persists to session on save" do
      draft_school_site.save!
      expect(request_session["draft_school"]).to eq(
        {
          "address_line_1" => "123 Main Street",
          "address_line_2" => "Floor 2",
          "address_postcode" => "SW1A 1AA",
          "address_town" => "London",
          "name" => "New Site Name",
          "urn" => school.urn,
          "wizard_step" => nil
        }
      )
    end

    it "clears session on clear!" do
      draft_school_site.save!
      draft_school_site.clear!
      expect(request_session["draft_school"]).to eq(
        {
          "address_line_1" => nil,
          "address_line_2" => nil,
          "address_postcode" => nil,
          "address_town" => nil,
          "name" => nil,
          "urn" => nil,
          "wizard_step" => nil
        }
      )
    end
  end
end
