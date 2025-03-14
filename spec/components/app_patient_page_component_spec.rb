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
    described_class.new(patient_session:, programme: programmes.first)
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
      expect(vaccinate_form.not_pregnant).to be(
        pre_screening_today.not_pregnant
      )
    end

    it "does not copy over vaccine-dependent responses to VaccinateForm" do
      expect(vaccinate_form.knows_vaccination).to be_nil
      expect(vaccinate_form.no_allergies).to be_nil
      expect(vaccinate_form.not_already_had).to be_nil
      expect(vaccinate_form.not_taking_medication).to be_nil
      expect(vaccinate_form.pre_screening_notes).to be_nil
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
      expect(vaccinate_form.pre_screening_notes).to be_nil
    end
  end
end
