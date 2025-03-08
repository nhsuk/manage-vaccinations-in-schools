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
    it { should_not have_css(".nhsuk-card__heading", text: "Triage notes") }

    it { should have_content("Is it safe to vaccinate") }

    it { should_not have_content("ready for their HPV vaccination?") }

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
    it { should have_css(".nhsuk-card__heading", text: "Triage notes") }

    it { should_not have_content("Is it safe to vaccinate") }

    it { should have_content("ready for their HPV vaccination?") }

    context "user is not allowed to triage or vaccinate" do
      before { stub_authorization(allowed: false) }

      it { should_not have_content("ready for their HPV vaccination?") }
    end
  end
end
