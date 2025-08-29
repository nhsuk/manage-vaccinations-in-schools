# frozen_string_literal: true

describe AppVaccinateFormComponent do
  subject { render_inline(component) }

  let(:programme) { create(:programme) }
  let(:programmes) { [programme] }
  let(:session) { create(:session, :today, programmes:) }
  let(:session_date) { session.session_dates.first }
  let(:patient) do
    create(
      :patient,
      :consent_given_triage_not_needed,
      programmes:,
      given_name: "Hari"
    )
  end
  let(:patient_session) do
    create(:patient_session, :in_attendance, programmes:, patient:, session:)
  end

  let(:vaccinate_form) do
    VaccinateForm.new(patient:, session_date:, programme:)
  end

  let(:component) { described_class.new(vaccinate_form) }

  before { patient_session.strict_loading!(false) }

  it { should have_css(".nhsuk-card") }

  context "with a flu programme and consent to nasal spray" do
    let(:programme) { create(:programme, :flu) }
    let(:academic_year) { Date.current.academic_year }

    before do
      patient.consent_status(programme:, academic_year:).update!(
        vaccine_methods: %w[nasal]
      )
    end

    it { should have_content("Has Hari confirmed their identity?") }
    it { should have_field("No, it was confirmed by somebody else") }

    it { should have_heading("Is Hari ready for their flu nasal spray?") }

    it { should have_field("Yes") }
    it { should have_field("No") }

    it { should_not have_field("Left arm (upper position)") }
    it { should_not have_field("Right arm (upper position)") }
    it { should_not have_field("Nose") }
    it { should_not have_field("Other") }
  end

  context "with a Flu programme" do
    let(:programme) { create(:programme, :flu) }

    it { should have_content("Has Hari confirmed their identity?") }
    it { should have_field("No, it was confirmed by somebody else") }

    it { should have_heading("Is Hari ready for their flu injection?") }

    it { should have_field("Yes") }
    it { should have_field("No") }

    it { should have_field("Left arm (upper position)") }
    it { should have_field("Right arm (upper position)") }
    it { should_not have_field("Nose") }
    it { should have_field("Other") }
  end

  context "with a flu programme, consent to nasal spray, but triaged for injection" do
    let(:programme) { create(:programme, :flu) }
    let(:academic_year) { Date.current.academic_year }

    before do
      patient.consent_status(programme:, academic_year:).update!(
        vaccine_methods: %w[nasal injection]
      )
      patient.triage_status(programme:, academic_year:).update!(
        status: "safe_to_vaccinate",
        vaccine_method: "injection"
      )
    end

    it { should have_heading("Is Hari ready for their flu injection?") }

    it { should have_field("Yes") }
    it { should have_field("No") }

    it { should have_field("Left arm (upper position)") }
    it { should have_field("Right arm (upper position)") }
    it { should_not have_field("Nose") }
    it { should have_field("Other") }
  end

  context "with an HPV programme" do
    let(:programme) { create(:programme, :hpv) }

    it { should have_content("Has Hari confirmed their identity?") }
    it { should have_field("No, it was confirmed by somebody else") }

    it { should have_heading("Is Hari ready for their HPV vaccination?") }

    it { should have_field("Yes") }
    it { should have_field("No") }

    it { should have_field("Left arm (upper position)") }
    it { should have_field("Right arm (upper position)") }
    it { should_not have_field("Nose") }
    it { should have_field("Other") }
  end
end
