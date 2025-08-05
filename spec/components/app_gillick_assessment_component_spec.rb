# frozen_string_literal: true

describe AppGillickAssessmentComponent do
  subject(:rendered) { render_inline(component) }

  let(:programmes) { [create(:programme, :hpv)] }
  let(:vaccine) { programme.vaccines.first }

  let(:component) do
    described_class.new(patient_session:, programme: programmes.first)
  end

  before { stub_authorization(allowed: true) }

  describe "rendered component" do
    subject { render_inline(component) }

    let(:patient_session) do
      create(
        :patient_session,
        :session_in_progress,
        :gillick_competent,
        programmes:
      )
    end

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
