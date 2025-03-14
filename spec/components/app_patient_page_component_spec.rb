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

  let(:programmes) { [create(:programme, :hpv), create(:programme, :menacwy)] }
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

    it { should have_content("ready for their HPV vaccination?") }

    context "user is not allowed to triage or vaccinate" do
      before { stub_authorization(allowed: false) }

      it { should_not have_content("ready for their HPV vaccination?") }
    end
  end

  describe "#default_vaccinate_form" do
    subject(:vaccinate_form) { component.default_vaccinate_form }

    let(:patient_session) { create(:patient_session, programmes:) }

    context "when a pre-screening from today's session and programme exists" do
      before do
        create(
          :pre_screening,
          patient_session:,
          programme: programmes.first,
          notes: "Today's prescreening"
        )
      end

      it "pre-checks the confirmation" do
        expect(vaccinate_form.pre_screening_confirmed).to be(true)
      end

      it "doesn't pre-fill the notes" do
        expect(vaccinate_form.pre_screening_notes).to be_nil
      end
    end

    context "when a pre-screening from today's session and different programme exists" do
      before do
        create(
          :pre_screening,
          patient_session:,
          programme: programmes.second,
          notes: "Today's prescreening"
        )
      end

      it "doesn't pre-check the confirmation" do
        expect(vaccinate_form.pre_screening_confirmed).to be(false)
      end

      it "doesn't pre-fill the notes" do
        expect(vaccinate_form.pre_screening_notes).to be_nil
      end
    end

    context "when a pre-screening from yesterday's session and programme exists" do
      before do
        create(
          :pre_screening,
          patient_session:,
          programme: programmes.first,
          created_at: 1.day.ago,
          notes: "Yesterday's prescreening"
        )
      end

      it "doesn't pre-check the confirmation" do
        expect(vaccinate_form.pre_screening_confirmed).to be(false)
      end

      it "doesn't pre-fill the notes" do
        expect(vaccinate_form.pre_screening_notes).to be_nil
      end
    end
  end
end
