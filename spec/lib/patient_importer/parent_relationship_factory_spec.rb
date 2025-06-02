# frozen_string_literal: true

describe PatientImporter::ParentRelationshipFactory do
  subject(:factory) { described_class.new(row_data, patient, bulk_import:) }

  let(:patient) { create(:patient) }
  let(:bulk_import) { false }

  describe "initialization" do
    let(:row_data) do
      {
        "parent_1_name" => "Jane Doe",
        "parent_1_email" => "jane@example.com",
        "parent_1_phone" => "07700900000",
        "parent_1_relationship" => "mother",
        "parent_2_name" => "John Doe",
        "parent_2_email" => "john@example.com",
        "parent_2_phone" => "07700900001",
        "parent_2_relationship" => "father",
        "other_attribute" => "value"
      }
    end

    it "defines accessor methods for parent attributes" do
      expect(factory.parent_1_name).to eq("Jane Doe")
      expect(factory.parent_1_email).to eq("jane@example.com")
      expect(factory.parent_1_phone).to eq("07700900000")
      expect(factory.parent_1_relationship).to eq("mother")
      expect(factory.parent_2_name).to eq("John Doe")
      expect(factory.parent_2_email).to eq("john@example.com")
      expect(factory.parent_2_phone).to eq("07700900001")
      expect(factory.parent_2_relationship).to eq("father")
    end
  end

  describe "#establish_family_connections" do
    context "when no parent data is provided" do
      let(:row_data) { {} }

      it "returns empty collections" do
        connections = factory.establish_family_connections
        expect(connections.parents).to be_empty
        expect(connections.parent_relationships).to be_empty
      end
    end

    context "when patient has pending changes and bulk import is true" do
      let(:bulk_import) { true }
      let(:row_data) do
        {
          "parent_1_name" => "Jane Doe",
          "parent_1_email" => "jane@example.com",
          "parent_1_relationship" => "mother"
        }
      end

      before do
        allow(patient).to receive(:pending_changes).and_return(
          { "gender_code" => "female" }
        )
      end

      it "returns empty collections" do
        connections = factory.establish_family_connections
        expect(connections.parents).to be_empty
        expect(connections.parent_relationships).to be_empty
      end
    end

    context "with both parents' data" do
      let(:row_data) do
        {
          "parent_1_name" => "Jane Doe",
          "parent_1_email" => "jane@example.com",
          "parent_1_phone" => "07700900000",
          "parent_1_relationship" => "mother",
          "parent_2_name" => "John Doe",
          "parent_2_email" => "john@example.com",
          "parent_2_phone" => "07700900001",
          "parent_2_relationship" => "father"
        }
      end

      it "creates two parents and relationships" do
        connections = factory.establish_family_connections

        expect(connections.parents.size).to eq(2)
        expect(connections.parent_relationships.size).to eq(2)

        mother = connections.parents.first
        expect(mother.full_name).to eq("Jane Doe")
        expect(mother.email).to eq("jane@example.com")
        expect(mother.phone).to eq("07700 900000")

        father = connections.parents.last
        expect(father.full_name).to eq("John Doe")
        expect(father.email).to eq("john@example.com")
        expect(father.phone).to eq("07700 900001")

        mother_relationship = connections.parent_relationships.first
        expect(mother_relationship.type).to eq("mother")

        father_relationship = connections.parent_relationships.last
        expect(father_relationship.type).to eq("father")
      end
    end

    context "with various relationship types" do
      let(:row_data) do
        {
          "parent_1_name" => "Jane Doe",
          "parent_1_email" => "jane@example.com",
          "parent_1_relationship" => relationship_type
        }
      end

      context "with 'mother' relationship" do
        let(:relationship_type) { "mother" }

        it "creates a relationship with type 'mother'" do
          connections = factory.establish_family_connections
          expect(connections.parent_relationships.first.type).to eq("mother")
        end
      end

      context "with 'mum' relationship" do
        let(:relationship_type) { "mum" }

        it "creates a relationship with type 'mother'" do
          connections = factory.establish_family_connections
          expect(connections.parent_relationships.first.type).to eq("mother")
        end
      end

      context "with 'father' relationship" do
        let(:relationship_type) { "father" }

        it "creates a relationship with type 'father'" do
          connections = factory.establish_family_connections
          expect(connections.parent_relationships.first.type).to eq("father")
        end
      end

      context "with 'dad' relationship" do
        let(:relationship_type) { "dad" }

        it "creates a relationship with type 'father'" do
          connections = factory.establish_family_connections
          expect(connections.parent_relationships.first.type).to eq("father")
        end
      end

      context "with 'guardian' relationship" do
        let(:relationship_type) { "guardian" }

        it "creates a relationship with type 'guardian'" do
          connections = factory.establish_family_connections
          expect(connections.parent_relationships.first.type).to eq("guardian")
        end
      end

      context "with 'unknown' relationship" do
        let(:relationship_type) { "unknown" }

        it "creates a relationship with type 'unknown'" do
          connections = factory.establish_family_connections
          expect(connections.parent_relationships.first.type).to eq("unknown")
        end
      end

      context "with nil relationship" do
        let(:relationship_type) { nil }

        it "creates a relationship with type 'unknown'" do
          connections = factory.establish_family_connections
          expect(connections.parent_relationships.first.type).to eq("unknown")
        end
      end

      context "with other relationship type" do
        let(:relationship_type) { "grandparent" }

        it "creates a relationship with type 'other' and sets other_name" do
          connections = factory.establish_family_connections
          relationship = connections.parent_relationships.first
          expect(relationship.type).to eq("other")
          expect(relationship.other_name).to eq("grandparent")
        end
      end
    end

    context "when existing parents are found" do
      let(:row_data) do
        {
          "parent_1_name" => "Jane Doe",
          "parent_1_email" => "jane@example.com",
          "parent_1_relationship" => "mother"
        }
      end

      let!(:existing_parent) do
        create(:parent, full_name: "Jane Smith", email: "jane@example.com")
      end

      it "updates existing parent attributes" do
        connections = factory.establish_family_connections

        parent = connections.parents.first
        expect(parent).to eq(existing_parent)
        expect(parent.full_name).to eq("Jane Doe")
      end
    end

    context "when existing relationship is found" do
      let(:row_data) do
        {
          "parent_1_name" => "Jane Doe",
          "parent_1_email" => "jane@example.com",
          "parent_1_relationship" => "mother"
        }
      end

      let(:existing_parent) do
        create(:parent, full_name: "Jane Doe", email: "jane@example.com")
      end
      let!(:existing_relationship) do
        create(
          :parent_relationship,
          parent: existing_parent,
          patient:,
          type: "guardian"
        )
      end

      it "updates existing relationship attributes" do
        connections = factory.establish_family_connections

        relationship = connections.parent_relationships.first
        expect(relationship.id).to eq(existing_relationship.id)
        expect(relationship.type).to eq("mother")
      end
    end
  end

  describe "FamilyConnections struct" do
    let(:parents) { [build(:parent), build(:parent)] }
    let(:relationships) do
      [build(:parent_relationship), build(:parent_relationship)]
    end
    let(:connections) do
      PatientImporter::ParentRelationshipFactory::FamilyConnections.new(
        parents,
        relationships
      )
    end

    describe "#save!" do
      it "saves all parents and relationships in a transaction" do
        expect(parents).to all(receive(:save!))
        expect(relationships).to all(receive(:save!))

        connections.save!
      end

      it "handles nil collections gracefully" do
        connections =
          PatientImporter::ParentRelationshipFactory::FamilyConnections.new(
            nil,
            nil
          )

        expect { connections.save! }.not_to raise_error
      end
    end
  end
end
