# frozen_string_literal: true

describe AppSessionPatientTableComponent do
  subject(:rendered) { render_inline(component) }

  before do
    allow(component).to receive(:session_patient_programme_path).and_return(
      "/session/patient/"
    )

    patient_sessions.each { _1.strict_loading!(false) }
  end

  let(:programmes) { [create(:programme)] }
  let(:session) { create(:session, programmes:) }
  let(:patient_sessions) { create_list(:patient_session, 2, session:) }
  let(:columns) { %i[name year_group] }
  let(:params) { { session_slug: session.slug } }

  let(:component) do
    described_class.new(
      patient_sessions,
      caption: "Foo",
      columns:,
      params:,
      programme: programmes.first
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

  context "when the patient has a common name" do
    let(:patient_sessions) do
      [
        create(
          :patient_session,
          programmes:,
          patient: create(:patient, preferred_given_name: "Bobby")
        )
      ]
    end

    it "includes the patient's common name" do
      expect(rendered).to have_text("Bobby")
    end
  end

  context "when the patient is restricted" do
    let(:patient_sessions) do
      [
        create(
          :patient_session,
          programmes:,
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

  describe "columns parameter" do
    context "is not set" do
      let(:component) do
        described_class.new(
          patient_sessions,
          programme: programmes.first,
          params:
        )
      end

      it { should have_column("Full name") }
      it { should have_column("Year group") }
    end

    context "includes action" do
      let(:columns) { %i[name year_group action] }

      it { should have_column("Action needed") }
    end

    context "includes status" do
      let(:columns) { %i[name year_group status] }

      it { should have_column("Status") }
    end

    context "includes date of birth" do
      let(:columns) { %i[name dob] }

      it { should have_column("Date of birth") }
    end
  end
end
