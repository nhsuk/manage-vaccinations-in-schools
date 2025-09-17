# frozen_string_literal: true

describe AppGillickAssessmentComponent do
  let(:programmes) { [create(:programme, :hpv)] }

  let(:component) do
    described_class.new(patient:, session:, programme: programmes.first)
  end

  before { stub_authorization(allowed: true) }

  describe "rendered component" do
    subject { render_inline(component) }

    let(:patient) { create(:patient) }
    let(:session) { create(:session, :today, programmes:) }

    before { create(:gillick_assessment, :competent, patient:, session:) }

    context "with a nurse user" do
      before { stub_authorization(allowed: true) }

      it { should have_link("Edit Gillick competence") }
      it { should have_heading("Gillick assessment") }
    end

    context "with an admin user" do
      before { stub_authorization(allowed: false) }

      it { should_not have_link("Edit Gillick competence") }
    end
  end
end
