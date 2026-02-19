# frozen_string_literal: true

describe AppVaccinateFormComponent do
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

  describe "#render" do
    subject { render_inline(component) }

    it { should have_css(".nhsuk-card") }

    context "with a flu programme" do
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

    context "with a flu programme and consent to nasal spray" do
      let(:programme) { Programme.flu }
      let(:academic_year) { AcademicYear.current }

      let(:patient) do
        create(
          :patient,
          :consent_given_nasal_only_triage_not_needed,
          :in_attendance,
          session:,
          given_name: "Hari"
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

    context "with a flu programme, consent to nasal spray, but triaged for injection" do
      let(:programme) { Programme.flu }
      let(:academic_year) { AcademicYear.current }

      let(:patient) do
        create(
          :patient,
          :consent_given_injection_and_nasal_triage_safe_to_vaccinate_injection,
          :in_attendance,
          session:,
          given_name: "Hari"
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

  describe "#dose_sequence" do
    subject { component.send(:dose_sequence) }

    context "with HPV programme" do
      let(:programme) { Programme.hpv }

      it { should eq(1) }
    end

    context "with Td/IPV programme" do
      let(:programme) { Programme.td_ipv }

      it { should be_nil }
    end

    context "with MenACWY programme" do
      let(:programme) { Programme.menacwy }

      it { should be_nil }
    end

    context "with flu programme" do
      let(:programme) { Programme.flu }

      it { should eq(1) }
    end

    context "with MMR programme" do
      let(:programme) { Programme.mmr }

      it { should be_nil }
    end
  end
end
