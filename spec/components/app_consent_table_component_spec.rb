# frozen_string_literal: true

describe AppConsentTableComponent do
  let(:component) { described_class.new(patient_session:, programme:) }

  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programmes: [programme]) }
  let(:patient) { patient_session.patient }

  before { patient.strict_loading!(false) }

  describe "#render?" do
    subject(:render?) { component.render? }

    it { should be(false) }

    context "with a consent response" do
      before { create(:consent, patient:, programme:) }

      it { should be(true) }
    end
  end

  describe "rendered component" do
    subject { render_inline(component) }

    context "consent is given" do
      let!(:consent) { create(:consent, :given, patient:, programme:) }

      it { should have_css("caption", text: "Consent responses") }
      it { should have_content(consent.parent.full_name) }
    end

    context "consent is refused" do
      let!(:consent) { create(:consent, :refused, patient:, programme:) }

      it { should have_css("caption", text: "Consent responses") }
      it { should have_content(consent.parent.full_name) }
    end

    context "consent is invalid" do
      before { create(:consent, :refused, :invalidated, patient:, programme:) }

      it { should have_css("td.app-table__cell-muted") }
    end
  end
end
