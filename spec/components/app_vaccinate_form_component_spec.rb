# frozen_string_literal: true

describe AppVaccinateFormComponent do
  subject { render_inline(component) }

  let(:programme) { Programme.sample }
  let(:programmes) { [programme] }

  let(:team) { create(:team, programmes:) }
  let(:current_user) { create(:user, team:) }

  let(:session) { create(:session, :today, team:, programmes:) }

  let(:patient) do
    create(
      :patient,
      :consent_given_triage_not_needed,
      :in_attendance,
      session:,
      given_name: "Hari"
    )
  end

  let(:vaccinate_form) do
    VaccinateForm.new(current_user:, patient:, session:, programme:)
  end

  let(:component) { described_class.new(vaccinate_form) }

  it { should have_css(".nhsuk-card") }

  context "with a flu programme and consent to nasal spray" do
    let(:programme) { Programme.flu }
    let(:academic_year) { AcademicYear.current }

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
    let(:programme) { Programme.flu }

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
    let(:programme) { Programme.flu }
    let(:academic_year) { AcademicYear.current }

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
    let(:programme) { Programme.hpv }

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
