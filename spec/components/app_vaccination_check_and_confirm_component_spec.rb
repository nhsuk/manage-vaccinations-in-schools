# frozen_string_literal: true

describe AppVaccinationCheckAndConfirmComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(vaccination_record, current_user:) }

  let(:current_user) { create(:user) }

  context "when administered" do
    let(:vaccination_record) { create(:vaccination_record) }

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
    let(:vaccination_record) { create(:vaccination_record, :not_administered) }

    it { should have_content("Child") }
    it { should have_content("Outcome") }
    it { should have_content("Date") }
    it { should have_content("Time") }
    it { should have_content("Location") }
    it { should have_content("Vaccinator") }
  end
end
