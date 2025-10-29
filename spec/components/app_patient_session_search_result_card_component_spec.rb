# frozen_string_literal: true

describe AppPatientSessionSearchResultCardComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) do
    described_class.new(patient:, session:, context:, programmes: [programme])
  end

  let(:patient) do
    create(
      :patient,
      :consent_given_injection_and_nasal_triage_safe_to_vaccinate_nasal,
      given_name: "Hari",
      family_name: "Seldon",
      address_postcode: "SW11 1AA",
      year_group: 8,
      school: build(:school, name: "Streeling University"),
      session:
    )
  end

  let(:programme) { create(:programme, :hpv) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:context) { :consent }

  let(:href) do
    "/sessions/#{session.slug}/patients/#{patient.id}/hpv?return_to=consent"
  end

  before { patient.strict_loading!(false) }

  it { should have_link("SELDON, Hari", href:) }
  it { should have_text("Year 8") }
  it { should have_text("Consent status") }
  it { should_not have_text("Vaccine type") }

  context "when patient session has notes" do
    let(:note) { create(:note, patient:, session:) }

    it { should have_text(note.body) }
    it { should_not have_link("Continue reading") }
  end

  context "when patient session has a long note" do
    before { create(:note, patient:, session:, body: "a long note " * 50) }

    it do
      expect(rendered).to have_text(
        "a long note a long note a long note a long note a long note a long note " \
          "a long note a long note a long note a long note a long note a long note " \
          "a long note a long note a long note a long note a long note a long note " \
          "a long note a long note a long note a long note a long note a long note " \
          "a long note a long note a long…"
      )
    end

    it { should have_link("Continue reading") }
  end

  context "when patient has notes from a different session" do
    let(:other_session) { create(:session, programmes: [programme]) }
    let(:note) { create(:note, patient:, session: other_session) }

    it { should_not have_text(note.body) }
    it { should_not have_link("Continue reading") }
  end

  context "when context is consent" do
    let(:context) { :consent }

    context "and the programme is flu" do
      let(:programme) { create(:programme, :flu) }

      it { should_not have_text("Vaccine type") }
      it { should have_text("Consent given for nasal spray") }

      context "and the vaccine method is overridden by triage" do
        let(:patient) do
          create(
            :patient,
            :consent_given_injection_and_nasal_triage_safe_to_vaccinate_injection,
            session:
          )
        end

        it { should_not have_text("Vaccine type") }
        it { should have_text("Consent given for gelatine-free injection") }
      end
    end
  end

  context "when context is triage" do
    let(:context) { :triage }

    context "and the programme is flu" do
      let(:programme) { create(:programme, :flu) }

      it { should_not have_text("Vaccine type") }
    end
  end

  context "when context is patient specific direction" do
    let(:context) { :patient_specific_direction }
    let(:programme) { create(:programme, :flu) }

    it { should have_text("PSD statusPSD not added") }

    context "with a PSD" do
      before { create(:patient_specific_direction, patient:, programme:) }

      it { should have_text("PSD statusPSD added") }
    end

    context "with an invalidated PSD" do
      before do
        create(:patient_specific_direction, :invalidated, patient:, programme:)
      end

      it { should have_text("PSD statusPSD not added") }
    end
  end

  context "when context is register" do
    let(:context) { :register }

    context "when allowed to record attendance" do
      before { stub_authorization(allowed: true) }

      it { should have_text("Vaccination status") }

      it { should have_text("Action requiredRecord vaccination for HPV") }
      it { should have_button("Attending") }
      it { should have_button("Absent") }

      context "and the programme is flu" do
        let(:programme) { create(:programme, :flu) }

        it { should have_text("Vaccine type") }
        it { should have_text("Nasal") }
      end
    end

    context "when not allowed to record attendance" do
      before { stub_authorization(allowed: false) }

      it { should have_text("Vaccination status") }

      it { should have_text("Action requiredRecord vaccination for HPV") }
      it { should_not have_button("Attending") }
      it { should_not have_button("Absent") }

      context "and the programme is flu" do
        let(:programme) { create(:programme, :flu) }

        it { should have_text("Vaccine type") }
        it { should have_text("Nasal") }
      end
    end
  end

  context "when context is record" do
    let(:context) { :record }

    it { should have_text("Action requiredRecord vaccination for HPV") }

    context "and the programme is flu" do
      let(:programme) { create(:programme, :flu) }
      let(:academic_year) { AcademicYear.current }

      it { should have_text("Vaccine type") }
      it { should have_text("Nasal") }

      context "and once vaccinated" do
        before do
          create(:vaccination_record, patient:, programme:, session:)
          patient.vaccination_status(programme:, academic_year:).assign_status
        end

        it { should_not have_text("Vaccine type") }
      end
    end
  end

  context "when context is patients" do
    let(:context) { :patients }

    it { should have_text("Vaccination status") }

    context "and the programme is flu" do
      let(:programme) { create(:programme, :flu) }

      it { should_not have_text("Vaccine type") }
    end
  end
end
