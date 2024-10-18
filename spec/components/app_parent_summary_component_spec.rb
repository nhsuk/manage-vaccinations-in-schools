# frozen_string_literal: true

describe AppParentSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(parent, relationship, change_links:) }

  let(:parent) { create(:parent, full_name: "John Smith") }
  let(:patient) { create(:patient) }
  let(:relationship) do
    create(:parent_relationship, :father, parent:, patient:)
  end
  let(:change_links) { {} }

  it { should have_content("Name") }
  it { should have_content("John Smith") }

  it { should have_content("Relationship") }
  it { should have_content("Dad") }

  context "with an email address" do
    let(:parent) { create(:parent, email: "test@example.com") }

    it { should have_content("Email address") }
    it { should have_content("test@example.com") }
  end

  context "with a phone number" do
    let(:parent) { create(:parent, phone: "07987654321") }

    it { should have_content("Phone number") }
    it { should have_content("07987654321") }
  end

  context "when the patient is restricted" do
    let(:patient) { create(:patient, :restricted) }

    it { should_not have_content("Email address") }
    it { should_not have_content("Phone number") }
  end

  it { should_not have_content("Change") }

  context "with change links" do
    let(:change_links) do
      {
        name: "/name",
        relationship: "/relationship",
        email: "/email",
        phone: "/phone"
      }
    end

    it { should have_content("Change name") }
    it { should have_content("Change relationship") }
    it { should have_content("Change email address") }
    it { should have_content("Change phone number") }
  end
end
