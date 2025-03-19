# frozen_string_literal: true

describe AppSessionActionsComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(session, patient_sessions:, outcomes:) }

  let(:programmes) { [create(:programme, :hpv)] }
  let(:session) { create(:session, programmes:) }
  let(:patient_sessions) { session.patient_sessions.preload_for_status }
  let(:outcomes) { Outcomes.new(patient_sessions:) }

  before do
    create(:patient_session, session:)
    create(:patient_session, :consent_conflicting, session:)
    create(:patient_session, :consent_given_triage_needed, session:)
    create(
      :patient_session,
      :consent_given_triage_not_needed,
      :in_attendance,
      session:
    )
    create(:patient_session, :vaccinated, session:)
  end

  it { should have_text("No consent response\n1 child") }
  it { should have_text("Conflicting consent\n1 child") }
  it { should have_text("Triage needed\n1 child") }
  it { should have_text("Register attendance\n3 child") }
  it { should have_text("Ready for vaccinator\n1 child for HPV") }
end
