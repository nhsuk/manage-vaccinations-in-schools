# frozen_string_literal: true

describe AppSessionActionsComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(session) }

  let(:programmes) { [create(:programme, :hpv)] }
  let(:session) { create(:session, programmes:) }

  let(:year_group) { 8 }

  let(:patient_without_nhs_number) do
    create(:patient, nhs_number: nil, year_group:)
  end

  before do
    create(
      :patient,
      :consent_no_response,
      :unknown_attendance,
      session:,
      year_group:
    )
    create(
      :patient,
      :consent_conflicting,
      :unknown_attendance,
      session:,
      year_group:
    )
    create(
      :patient,
      :consent_given_triage_needed,
      :unknown_attendance,
      session:,
      year_group:
    )
    create(
      :patient,
      :consent_given_triage_not_needed,
      :in_attendance,
      session:,
      year_group:
    )
    create(:patient, :vaccinated, :in_attendance, session:, year_group:)
    create(:patient, nhs_number: nil, session:, year_group:)
    create(:consent_form, :recorded, session:)
  end

  it { should have_text("No NHS number1 child") }
  it { should have_text("Unmatched response1 unmatched response") }
  it { should have_text("No consent response1 child") }
  it { should have_text("Conflicting consent1 child") }
  it { should have_text("Triage needed1 child") }
  it { should have_text("Register attendance3 child") }
  it { should have_text("Ready for vaccinator1 child for HPV") }

  it { should have_link("1 child without an NHS number") }
  it { should have_link("1 unmatched response") }
  it { should have_link("1 child with no response") }
  it { should have_link("1 child with conflicting response") }
  it { should have_link("1 child requiring triage") }
  it { should have_link("3 children to register") }
  it { should have_link("1 child for HPV") }

  context "session requires no registration" do
    let(:session) { create(:session, :requires_no_registration, programmes:) }

    it { should_not have_link("Review register attendance") }
  end

  context "when patients are not eligible for the programme" do
    let(:year_group) { 7 }

    it { should_not have_text("No consent response") }
    it { should_not have_text("Conflicting consent") }
    it { should_not have_text("Triage needed") }
    it { should_not have_text("Register attendance") }
    it { should_not have_text("Ready for vaccinator") }
  end

  context "when there are no action required" do
    before do
      PatientLocation.destroy_all
      ConsentForm.destroy_all
    end

    it { should have_text("No action required") }
  end
end
