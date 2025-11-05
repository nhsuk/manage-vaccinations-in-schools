# frozen_string_literal: true

describe AppTriageFormComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(triage_form, url:) }
  let(:url) { "/triage" }

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programmes: [programme]) }
  let(:patient) { create(:patient, session:) }

  let(:triage_form) { TriageForm.new(patient:, session:, programme:) }

  it { should have_css("h2") }
  it { should have_text("Is it safe to vaccinate") }

  describe "without a heading" do
    let(:component) { described_class.new(triage_form, url:, heading: false) }

    it { should_not have_css("h2") }
  end

  describe "hint text and triage options for consented delivery method(s)" do
    let(:programme) { create(:programme, :flu) }

    context "when only injection is consented to" do
      before do
        create(
          :patient_consent_status,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[injection]
        )
      end

      it "shows the correct hint about injection only" do
        expect(rendered).to have_text(
          "The parent has consented to the injected vaccine only"
        )
      end

      it "shows the correct safe triage option for injection only" do
        expect(rendered).to have_text("safe to vaccinate with injected vaccine")
        expect(rendered).not_to have_text("safe to vaccinate with nasal spray")
      end
    end

    context "when both nasal and injection are consented to" do
      before do
        create(
          :patient_consent_status,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[injection nasal]
        )
      end

      it "shows the correct hint about injection being offered" do
        expect(rendered).to have_text(
          "The parent has consented to the injected vaccine being offered if the nasal spray is not suitable"
        )
      end

      it "shows the correct safe triage options for nasal and injection" do
        expect(rendered).to have_text("safe to vaccinate with injected vaccine")
        expect(rendered).to have_text("safe to vaccinate with nasal spray")
      end
    end

    context "when only nasal is consented to" do
      before do
        create(
          :patient_consent_status,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal]
        )
      end

      it "shows the correct hint about nasal spray only" do
        expect(rendered).to have_text(
          "The parent has consented to the nasal spray only"
        )
      end

      it "shows the correct safe triage option for nasal only" do
        expect(rendered).not_to have_text(
          "safe to vaccinate with injected vaccine"
        )
        expect(rendered).to have_text("safe to vaccinate with nasal spray")
      end
    end
  end

  context "when programme does not have multiple delivery methods" do
    let(:programme) { create(:programme, :hpv) }

    before do
      create(
        :patient_consent_status,
        :given,
        patient:,
        programme:,
        vaccine_methods: %w[injection]
      )
    end

    it "shows only the generic safe to vaccinate option, and no hint" do
      expect(rendered).to have_text("safe to vaccinate")
      expect(rendered).not_to have_text(
        "safe to vaccinate with injected vaccine"
      )
      expect(rendered).not_to have_text("safe to vaccinate with nasal spray")
      expect(rendered).not_to have_text("The parent has consented to")
    end
  end

  context "hint text for delayed triage when programme is MMR" do
    context "when the patient has not received any dose" do
      let(:programme) { create(:programme, :mmr) }

      it "doesn't show the specific hint text about the 2nd dose" do
        expect(rendered).not_to have_text("2nd dose is not due until")
      end
    end

    context "when the patient has received the 1st dose" do
      let(:programme) { create(:programme, :mmr) }

      before do
        create(:vaccination_record, patient:, programme:, session:)

        StatusUpdater.call(patient:)
      end

      it "doesn't show the specific hint text about the 2nd dose" do
        expect(rendered).to have_text("2nd dose is not due until")
      end
    end
  end
end
