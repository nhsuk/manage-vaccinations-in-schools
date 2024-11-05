# frozen_string_literal: true

describe AppVaccinationCheckAndConfirmComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(vaccination_record, current_user:, change_links:)
  end

  let(:current_user) { create(:user) }
  let(:change_links) { {} }

  context "when administered" do
    let(:vaccination_record) { build(:vaccination_record) }

    it { should have_content("Child") }
    it { should have_content("Vaccine") }
    it { should have_content("Brand") }
    it { should have_content("Batch") }
    it { should have_content("Method") }
    it { should have_content("Site") }
    it { should have_content("Outcome") }
    it { should have_content("Date") }
    it { should have_content("Time") }
    it { should have_content("Location") }
    it { should have_content("Vaccinator") }

    context "if performed by current user" do
      before { vaccination_record.performed_by = current_user }

      it { should have_content("You") }
    end
  end

  context "when not administered" do
    let(:vaccination_record) { build(:vaccination_record, :not_administered) }

    it { should have_content("Child") }
    it { should have_content("Outcome") }
    it { should have_content("Date") }
    it { should have_content("Time") }
    it { should have_content("Location") }
    it { should have_content("Vaccinator") }
  end

  context "with change links" do
    let(:vaccination_record) { build(:vaccination_record) }

    let(:change_links) do
      {
        batch: "/batch",
        delivery_method: "/delivery-method",
        delivery_site: "/delivery-site",
        location: "/location",
        outcome: "/outcome"
      }
    end

    it { should have_link("Change batch", href: "/batch") }
    it { should have_link("Change method", href: "/delivery-method") }
    it { should have_link("Change site", href: "/delivery-site") }
    it { should have_link("Change location", href: "/location") }
    it { should have_link("Change outcome", href: "/outcome") }
  end
end
