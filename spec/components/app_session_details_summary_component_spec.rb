# frozen_string_literal: true

describe AppSessionDetailsSummaryComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(session, patient_sessions:, outcomes:) }

  let(:programme) { create(:programme, :hpv) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient_sessions) { session.patient_sessions.preload_for_status }
  let(:outcomes) { Outcomes.new(patient_sessions: patient_sessions) }

  it { should have_text("Cohort\nNo children") }
  it { should have_text("Consent refused\nNo children") }
  it { should have_text("Vaccinated\nNo vaccinations given for HPV") }

  context "with activity" do
    before do
      create(:patient_session, session:)
      create(:patient_session, :consent_refused, session:)
      create(:patient_session, :vaccinated, session:)
    end

    it { should have_text("Cohort\n3 children") }
    it { should have_text("Consent refused\n1 child") }
    it { should have_text("Vaccinated\n1 vaccination given for HPV") }
  end
end
