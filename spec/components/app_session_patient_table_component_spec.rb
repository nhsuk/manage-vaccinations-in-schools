# frozen_string_literal: true

describe AppSessionPatientTableComponent do
  subject(:rendered) { render_inline(component) }

  before do
    allow(component).to receive(:session_patient_path).and_return(
      "/session/patient/"
    )
  end

  let(:section) { :consent }
  let(:programme) { create(:programme) }
  let(:session) { create(:session, programme:) }
  let(:patient_sessions) { create_list(:patient_session, 2, session:) }
  let(:columns) { %i[name year_group] }
  let(:params) { { session_id: 1, section:, tab: :needed } }

  let(:component) do
    described_class.new(
      session:,
      patient_sessions:,
      caption: "Foo",
      section:,
      columns:,
      params:
    )
  end

  def have_column(text)
    have_css(".nhsuk-table__head th", text:)
  end

  it { should have_css(".nhsuk-table") }
  it { should have_css(".nhsuk-table__head") }
  it { should have_column("Full name") }
  it { should have_column("Year group") }
  it { should have_css(".nhsuk-table__head .nhsuk-table__row", count: 1) }

  it "includes the patient's full name" do
    expect(rendered).to have_text(patient_sessions.first.patient.full_name)
  end

  describe "when the patient has a common name" do
    let(:patient_sessions) do
      [
        create(
          :patient_session,
          programme:,
          patient: create(:patient, common_name: "Bobby")
        )
      ]
    end

    it "includes the patient's common name" do
      expect(rendered).to have_text("Bobby")
    end
  end

  describe "when the patient is restricted" do
    let(:patient_sessions) do
      [
        create(
          :patient_session,
          programme:,
          patient: create(:patient, :restricted, address_postcode: "SW11 1AA")
        )
      ]
    end

    it "doesn't show the postcode" do
      expect(rendered).not_to have_text("SW11 1AA")
    end
  end

  it { should have_css(".nhsuk-table__body") }
  it { should have_css(".nhsuk-table__body .nhsuk-table__row", count: 2) }
  it { should have_link(patient_sessions.first.patient.full_name) }

  describe "when the section is :matching" do
    let(:component) do
      described_class.new(
        session:,
        patient_sessions:,
        section: :matching,
        consent_form:
          create(
            :consent_form,
            programme:,
            session: patient_sessions.first.session
          ),
        columns: %i[name postcode year_group select_for_matching]
      )
    end

    it { should have_column("Action") }
    it { should have_column("Postcode") }
    it { should_not have_link(patient_sessions.first.patient.full_name) }
  end

  context "vaccinations section" do
    let(:section) { :vaccination }
    let(:tab) { :actions }

    it do
      expect(subject).to have_link(
        patient_sessions.first.patient.full_name,
        href: "/session/patient/"
      )
    end
  end

  describe "columns parameter" do
    context "is not set" do
      let(:component) do
        described_class.new(session:, patient_sessions:, section:, params:)
      end

      it { should have_column("Full name") }
      it { should have_column("Year group") }
    end

    context "includes action" do
      let(:columns) { %i[name year_group action] }

      it { should have_column("Action needed") }
    end

    context "includes outcome" do
      let(:columns) { %i[name year_group outcome] }

      it { should have_column("Outcome") }
    end
  end
end
