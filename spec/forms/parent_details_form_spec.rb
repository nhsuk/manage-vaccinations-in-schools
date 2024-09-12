# frozen_string_literal: true

describe ParentDetailsForm, type: :model do
  subject(:form) do
    described_class.new(
      parent:,
      patient:,
      email:,
      name:,
      phone:,
      parental_responsibility:,
      relationship_type:,
      relationship_other_name:
    )
  end

  let(:parent) { build(:parent) }
  let(:patient) { create(:patient) }

  let(:email) { "" }
  let(:name) { "" }
  let(:phone) { "" }
  let(:parental_responsibility) { "" }
  let(:relationship_type) { "" }
  let(:relationship_other_name) { "" }

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }

    it do
      expect(form).to validate_inclusion_of(:relationship_type).in_array(
        %w[mother father guardian other]
      )
    end

    context "when relationship type is other" do
      let(:relationship_type) { "other" }

      it { should validate_presence_of(:relationship_other_name) }
    end
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:email) { "john.smith@example.com" }
    let(:name) { "John Smith" }
    let(:parental_responsibility) { "yes" }
    let(:relationship_type) { "father" }

    it "updates the parent" do
      expect(save).to be(true)

      expect(parent).to have_attributes(email:, name:)
    end

    it "creates a parent relationship" do
      expect(save).to be(true)

      expect(parent.patients).to include(patient)
      expect(parent.parent_relationships.first).to be_father
    end
  end
end
