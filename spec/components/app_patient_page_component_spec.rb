# frozen_string_literal: true

describe AppPatientPageComponent do
  subject(:rendered) { render_inline(component) }

  before do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(AppSimpleStatusBannerComponent).to receive(
      :new_session_patient_programme_triages_path
    ).and_return("/session/patient/triage/new")
    # rubocop:enable RSpec/AnyInstance
    stub_authorization(allowed: true)

    patient_session.strict_loading!(false)
  end

  let(:programmes) { [create(:programme, :hpv)] }
  let(:vaccine) { programme.vaccines.first }

  let(:component) do
    described_class.new(
      patient_session:,
      programme: programmes.first,
      triage: nil
    )
  end

  context "session in progress, patient in triage" do
    let(:patient_session) do
      create(
        :patient_session,
        :consent_given_triage_needed,
        :session_in_progress,
        programmes:
      )
    end

    it { should have_css(".nhsuk-card__heading", text: "Child") }
    it { should have_css(".nhsuk-card__heading", text: "Consent") }
    it { should_not have_css(".nhsuk-card__heading", text: "Triage notes") }

    it { should have_content("Is it safe to vaccinate") }

    it { should_not have_content("ready for their HPV vaccination?") }

    it { should have_css("a", text: "Assess Gillick competence") }

    context "user is not allowed to triage or vaccinate" do
      before { stub_authorization(allowed: false) }

      it { should_not have_content("Is it safe to vaccinate") }
    end
  end

  context "session in progress, patient ready to vaccinate" do
    let(:patient_session) do
      create(
        :patient_session,
        :triaged_ready_to_vaccinate,
        :session_in_progress,
        :in_attendance,
        programmes:
      )
    end

    it { should have_css(".nhsuk-card__heading", text: "Child") }
    it { should have_css(".nhsuk-card__heading", text: "Consent") }
    it { should have_css(".nhsuk-card__heading", text: "Triage notes") }

    it { should_not have_content("Is it safe to vaccinate") }

    it { should have_content("ready for their HPV vaccination?") }

    context "user is not allowed to triage or vaccinate" do
      before { stub_authorization(allowed: false) }

      it { should_not have_content("ready for their HPV vaccination?") }
    end
  end

  context "session in progress, patient without consent, no Gillick assessment" do
    let(:patient_session) do
      create(:patient_session, :session_in_progress, programmes:)
    end

    context "nurse user" do
      before { stub_authorization(allowed: true) }

      it { should have_css("a", text: "Assess Gillick competence") }
    end

    context "admin user" do
      before { stub_authorization(allowed: false) }

      it { should_not have_css("a", text: "Assess Gillick competence") }
    end
  end

  context "session in progress, patient without consent, Gillick assessment" do
    let(:patient_session) do
      create(
        :patient_session,
        :session_in_progress,
        :gillick_competent,
        programmes:
      )
    end

    context "nurse user" do
      before { stub_authorization(allowed: true) }

      it { should have_css("a", text: "Edit Gillick competence") }

      it "shows the Gillick assessment" do
        expect(rendered).to have_css(
          ".nhsuk-card__heading",
          text: "Gillick assessment"
        )
      end
    end

    context "admin user" do
      before { stub_authorization(allowed: false) }

      it { should_not have_css("a", text: "Edit Gillick competence") }
    end
  end

  context "when a pre_screening from today's session date is present" do
    subject(:vaccinate_form) { component.default_vaccinate_form }

    let(:today) { Date.current }
    let(:patient_session) do
      create(:patient_session, :session_in_progress, programmes:)
    end
    let(:session_date_today) { SessionDate.find_or_create_by(value: today) }
    let!(:pre_screening_today) do
      create(
        :pre_screening,
        patient_session: patient_session,
        session_date: session_date_today,
        feeling_well: true,
        knows_vaccination: false,
        no_allergies: true,
        not_already_had: false,
        not_pregnant: true,
        not_taking_medication: true,
        notes: "Today's prescreening"
      )
    end

    it "initializes VaccinateForm with today's pre_screening data" do
      expect(vaccinate_form.feeling_well).to be(
        pre_screening_today.feeling_well
      )
      expect(vaccinate_form.knows_vaccination).to be(
        pre_screening_today.knows_vaccination
      )
      expect(vaccinate_form.no_allergies).to be(
        pre_screening_today.no_allergies
      )
      expect(vaccinate_form.not_already_had).to be(
        pre_screening_today.not_already_had
      )
      expect(vaccinate_form.not_pregnant).to be(
        pre_screening_today.not_pregnant
      )
      expect(vaccinate_form.not_taking_medication).to be(
        pre_screening_today.not_taking_medication
      )
      expect(vaccinate_form.pre_screening_notes).to eq(
        pre_screening_today.notes
      )
    end
  end

  context "when no pre_screening from today's session date is present" do
    subject(:vaccinate_form) { component.default_vaccinate_form }

    let(:today) { Date.current }
    let(:patient_session) do
      create(:patient_session, :session_in_progress, programmes:)
    end
    let(:session_date_yesterday) { create(:session_date, value: today - 1) }
    let(:pre_screening_yesterday) do
      create(
        :pre_screening,
        patient_session: patient_session,
        session_date: session_date_yesterday,
        feeling_well: true,
        knows_vaccination: true,
        no_allergies: true,
        not_already_had: true,
        not_pregnant: true,
        not_taking_medication: true,
        notes: "Yesterday's prescreening"
      )
    end

    it "initializes VaccinateForm with blank pre_screening data" do
      expect(vaccinate_form.feeling_well).to be_nil
      expect(vaccinate_form.knows_vaccination).to be_nil
      expect(vaccinate_form.no_allergies).to be_nil
      expect(vaccinate_form.not_already_had).to be_nil
      expect(vaccinate_form.not_pregnant).to be_nil
      expect(vaccinate_form.not_taking_medication).to be_nil
      expect(vaccinate_form.pre_screening_notes).to eq("")
    end
  end
end
