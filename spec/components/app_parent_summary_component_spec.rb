# frozen_string_literal: true

describe AppParentSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(parent_relationship:) }

  let(:parent) { create(:parent, full_name: "John Smith") }
  let(:patient) { create(:patient) }
  let(:parent_relationship) do
    create(:parent_relationship, :father, parent:, patient:)
  end

  it { should_not have_content("Name") }
  it { should_not have_content("Relationship") }

  context "when showing name and relationship" do
    let(:component) do
      described_class.new(
        parent_relationship:,
        show_name_and_relationship: true
      )
    end

    it { should have_content("Name") }
    it { should have_content("SMITH, John") }

    it { should have_content("Relationship") }
    it { should have_content("Dad") }
  end

  context "with an email address" do
    let(:parent) { create(:parent, email: "test@example.com") }

    it { should have_content("Email address") }
    it { should have_content("test@example.com") }

    context "with a delivery failure" do
      before do
        create(
          :notify_log_entry,
          :email,
          :permanent_failure,
          parent:,
          recipient: parent.email
        )
      end

      it { should have_content("Email address does not exist") }
    end
  end

  context "with a phone number" do
    let(:parent) { create(:parent, phone: "07987654321") }

    it { should have_content("Phone number") }
    it { should have_content("07987 654321") }

    context "with a delivery failure" do
      before do
        create(
          :notify_log_entry,
          :sms,
          :permanent_failure,
          parent:,
          recipient: parent.phone
        )
      end

      it { should have_content("Phone number does not exist") }
    end
  end

  context "when the patient is restricted" do
    let(:patient) { create(:patient, :restricted) }

    it { should_not have_content("Email address") }
    it { should_not have_content("Phone number") }
  end

  it { should_not have_content("Change") }

  context "with change links" do
    let(:component) do
      described_class.new(
        parent_relationship:,
        change_links:,
        show_name_and_relationship: true
      )
    end

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
