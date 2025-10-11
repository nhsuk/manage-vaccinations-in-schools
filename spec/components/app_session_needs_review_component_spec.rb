# frozen_string_literal: true

describe AppSessionNeedsReviewComponent do
  let(:component) { described_class.new(session) }

  let(:session) { create(:session) }

  describe "#render?" do
    subject { component.render? }

    context "when session has no patients without NHS number" do
      it { should be(false) }
    end

    context "when session has a patient without an NHS number" do
      before { create(:patient, nhs_number: nil, session:) }

      it { should be(true) }
    end
  end

  describe "rendered content" do
    subject { render_inline(component) }

    context "when session has a patient without an NHS number" do
      before { create(:patient, nhs_number: nil, session:) }

      it { should have_text("1 child without an NHS number") }
      it { should have_link(href: /missing_nhs_number=true/) }
    end

    context "when session has multiple patients without an NHS number" do
      before { create_list(:patient, 3, nhs_number: nil, session:) }

      it { should have_text("3 children without an NHS number") }
    end
  end
end
