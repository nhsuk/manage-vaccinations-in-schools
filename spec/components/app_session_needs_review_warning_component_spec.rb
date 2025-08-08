# frozen_string_literal: true

describe AppSessionNeedsReviewWarningComponent do
  let(:component) { described_class.new(session:) }
  let(:session) { create(:session) }

  describe "#render?" do
    subject { component.render? }

    context "when session has no patients without NHS number" do
      it { should be(false) }
    end

    context "when session has patients without NHS number" do
      before { create(:patient, nhs_number: nil, session:) }

      it { should be(true) }
    end
  end

  describe "rendered content" do
    subject(:rendered) { render_inline(component) }

    context "when session has patients without NHS number" do
      before do
        create(
          :patient,
          nhs_number: nil,
          patient_sessions: [build(:patient_session, session:)],
          year_group: session.programmes.sample.default_year_groups.sample
        )
      end

      it "shows the count of children without NHS number" do
        expect(rendered).to have_text("1")
      end

      it "has a link to the consent page with missing_nhs_number parameter" do
        expect(rendered).to have_link(href: /missing_nhs_number=true/)
      end

      it "uses the correct translation key for the link text" do
        expect(rendered).to have_text(
          I18n.t(:children_without_nhs_number, count: 1)
        )
      end
    end

    context "when session has multiple patients without NHS number" do
      before { create_list(:patient, 3, nhs_number: nil, session:) }

      it "shows the correct count of children without NHS number" do
        expect(rendered).to have_text("3")
      end
    end
  end
end
