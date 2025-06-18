# frozen_string_literal: true

describe AppVaccinateFormComponent do
  subject { render_inline(component) }

  let(:programme) { create(:programme) }
  let(:programmes) { [programme] }
  let(:session) { create(:session, :today, programmes:) }
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

  let(:vaccinate_form) { VaccinateForm.new(patient_session:, programme:) }

  let(:component) { described_class.new(vaccinate_form) }

  before { patient_session.strict_loading!(false) }

  describe "#render?" do
    subject(:render) { component.render? }

    it { should be(true) }

    context "patient is not ready for vaccination" do
      let(:patient) { create(:patient, programmes:, given_name: "Hari") }

      it { should be(false) }
    end

    context "patient is not attending the session" do
      let(:patient_session) do
        create(:patient_session, programmes:, patient:, session:)
      end

      it { should be(false) }
    end
  end

  describe "rendered content" do
    subject { render_inline(component) }

    it { should have_css(".nhsuk-card") }

    context "with a Flu programme and consent to nasal spray" do
      let(:programme) { create(:programme, :flu) }

      before do
        patient.consent_status(programme:).update!(vaccine_methods: %w[nasal])
      end

      it { should have_heading("Is Hari ready for their Flu vaccination?") }

      it { should have_field("Yes") }
      it { should have_field("No") }

      it { should_not have_field("Left arm (upper position)") }
      it { should_not have_field("Right arm (upper position)") }
      it { should_not have_field("Nose") }
      it { should_not have_field("Other") }
    end

    context "with an HPV programme" do
      let(:programme) { create(:programme, :hpv) }

      it { should have_heading("Is Hari ready for their HPV vaccination?") }

      it { should have_field("Yes") }
      it { should have_field("No") }

      it { should have_field("Left arm (upper position)") }
      it { should have_field("Right arm (upper position)") }
      it { should_not have_field("Nose") }
      it { should have_field("Other") }
    end
  end
end
