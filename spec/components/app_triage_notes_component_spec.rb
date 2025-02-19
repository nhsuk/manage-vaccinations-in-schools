# frozen_string_literal: true

describe AppTriageNotesComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient_session:, programme:) }

  let(:programme) { create(:programme) }
  let(:patient_session) { create(:patient_session, programme:) }
  let(:patient) { patient_session.patient }

  before { patient_session.strict_loading!(false) }

  context "triage notes are not present" do
    it "does not render" do
      expect(component.render?).to be(false)
    end
  end

  context "a single triage note is present" do
    let(:performed_by) { create(:user, family_name: "Gear", given_name: "Joe") }

    before do
      create(
        :triage,
        :ready_to_vaccinate,
        programme:,
        notes: "Some notes",
        patient:,
        performed_by:,
        created_at: Time.zone.local(2023, 12, 4, 10, 4)
      )
    end

    it "renders" do
      expect(component.render?).to be(true)
    end

    it { should have_css("h3", text: "Triaged decision: Safe to vaccinate") }
    it { should have_css("p", text: "Some notes") }
    it { should have_css("p", text: "4 December 2023 at 10:04am") }
    it { should have_css("p", text: "GEAR, Joe") }
    it { should_not have_css("hr") }
  end

  context "with an invalidated triage" do
    before do
      create(:triage, :invalidated, programme:, notes: "Some notes", patient:)
    end

    it { should have_css("s", text: "Triaged decision: Safe to vaccinate") }
    it { should have_css("s", text: "Some notes") }
  end

  context "multiple triage notes are present" do
    before { create_list(:triage, 2, programme:, patient:) }

    it "renders" do
      expect(component.render?).to be(true)
    end

    it { should have_css("hr") }
  end

  context "with a pre-screening" do
    let(:performed_by) { create(:user, family_name: "Gear", given_name: "Joe") }

    before do
      create(
        :pre_screening,
        :allows_vaccination,
        patient_session:,
        notes: "Some notes",
        performed_by:,
        created_at: Time.zone.local(2023, 12, 4, 10, 4)
      )
    end

    it "renders" do
      expect(component.render?).to be(true)
    end

    it { should have_css("h3", text: "Completed pre-screening checks") }
    it { should have_css("p", text: "Some notes") }
    it { should have_css("p", text: "4 December 2023 at 10:04am") }
    it { should have_css("p", text: "GEAR, Joe") }
    it { should_not have_css("hr") }
  end
end
