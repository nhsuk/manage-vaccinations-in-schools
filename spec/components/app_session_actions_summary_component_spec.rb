# frozen_string_literal: true

describe AppSessionActionsSummaryComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(session, patient_sessions:) }

  let(:session) { create(:session) }
  let(:patient_sessions) { session.patient_sessions.preload_for_status }

  before do
    create(:patient_session, session:)
    create(:patient_session, :consent_conflicting, session:)
    create(:patient_session, :consent_given_triage_needed, session:)
    create(:patient_session, :consent_given_triage_not_needed, session:)
    create(:patient_session, :vaccinated, session:)
  end

  it { should have_text("Get consent\n1 child without a response") }
  it { should have_text("Resolve consent\n1 child with conflicting consent") }
  it { should have_text("Triage\n1 child") }
  it { should have_text("Register attendance\n1 child") }
end
