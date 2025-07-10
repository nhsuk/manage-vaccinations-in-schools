# frozen_string_literal: true

describe AppSessionActionsComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(session) }

  let(:programmes) { [create(:programme, :hpv)] }
  let(:session) { create(:session, programmes:) }

  before do
    create(
      :patient_session,
      :consent_no_response,
      :unknown_attendance,
      session:
    )
    create(
      :patient_session,
      :consent_conflicting,
      :unknown_attendance,
      session:
    )
    create(
      :patient_session,
      :consent_given_triage_needed,
      :unknown_attendance,
      session:
    )
    create(
      :patient_session,
      :consent_given_triage_not_needed,
      :in_attendance,
      session:
    )
    create(:patient_session, :vaccinated, :in_attendance, session:)
  end

  it { should have_text("No consent response\n1 child") }
  it { should have_text("Conflicting consent\n1 child") }
  it { should have_text("Triage needed\n1 child") }
  it { should have_text("Register attendance\n3 child") }
  it { should have_text("Ready for vaccinator\n1 child for HPV") }

  it { should have_link("Review no consent response") }
  it { should have_link("Review conflicting consent") }
  it { should have_link("Review triage needed") }
  it { should have_link("Review register attendance") }
  it { should have_link("Review ready for vaccinator") }

  context "session requires no registration" do
    let(:session) { create(:session, :requires_no_registration, programmes:) }

    it { should_not have_link("Review register attendance") }
  end
end
