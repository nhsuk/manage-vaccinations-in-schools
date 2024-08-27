# frozen_string_literal: true

describe AppPatientTableComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  before do
    allow(component).to receive(:session_patient_path).and_return(
      "/session/patient/"
    )
  end

  let(:section) { :consent }
  let(:campaign) { create(:campaign) }
  let(:patient_sessions) do
    create_list(:patient_session, 2, session_attributes: { campaign: })
  end
  let(:columns) { %i[name dob] }
  let(:params) { { session_id: 1, section:, tab: :needed } }
  let(:args) do
    { patient_sessions:, caption: "Foo", section:, columns:, params: }
  end

  let(:component) { described_class.new(**args) }

  def have_column(text)
    have_css(".nhsuk-table__head th", text:)
  end

  it { should have_css(".nhsuk-table") }
  it { should have_css(".nhsuk-table__head") }
  it { should have_column("Full name") }
  it { should have_column("Date of birth") }
  it { should have_css(".nhsuk-table__head .nhsuk-table__row", count: 1) }

  it "includes the patient's full name" do
    expect(rendered).to have_text(patient_sessions.first.patient.full_name)
  end

  describe "when the patient has a common name" do
    let(:patient_sessions) do
      create_list(
        :patient_session,
        2,
        session_attributes: {
          campaign:
        },
        patient_attributes: {
          common_name: "Bobby"
        }
      )
    end

    it "includes the patient's common name" do
      expect(rendered).to have_text("Bobby")
    end
  end

  it { should have_css(".nhsuk-table__body") }
  it { should have_css(".nhsuk-table__body .nhsuk-table__row", count: 2) }
  it { should have_link(patient_sessions.first.patient.full_name) }

  describe "when the section is :matching" do
    let(:component) do
      described_class.new(
        patient_sessions:,
        section: :matching,
        consent_form:
          create(:consent_form, session: patient_sessions.first.session),
        columns: %i[name postcode dob select_for_matching]
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
      let(:component) { described_class.new(**args.except(:columns)) }

      it { should have_column("Full name") }
      it { should have_column("Date of birth") }
    end

    context "includes action" do
      let(:columns) { %i[name dob action] }

      it { should have_column("Action needed") }
    end

    context "includes outcome" do
      let(:columns) { %i[name dob outcome] }

      it { should have_column("Outcome") }
    end
  end
end
