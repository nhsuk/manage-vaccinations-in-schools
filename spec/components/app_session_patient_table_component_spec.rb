# frozen_string_literal: true

describe AppSessionPatientTableComponent do
  subject(:rendered) { render_inline(component) }

  before do
    allow(component).to receive(:session_patient_programme_path).and_return(
      "/session/patient/"
    )

    patient_sessions.each { _1.strict_loading!(false) }
  end

  let(:section) { :consent }
  let(:programme) { create(:programme) }
  let(:session) { create(:session, programme:) }
  let(:patient_sessions) { create_list(:patient_session, 2, session:) }
  let(:columns) { %i[name year_group] }
  let(:params) { { session_slug: session.slug, section:, tab: :needed } }

  let(:component) do
    described_class.new(
      caption: "Foo",
      columns:,
      params:,
      patient_sessions:,
      section:,
      programme:,
      year_groups: session.year_groups
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
          programme:,
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

  context "when the section is :matching" do
    let(:component) do
      described_class.new(
        patient_sessions:,
        programme:,
        section: :matching,
        consent_form:
          create(:consent_form, session: patient_sessions.first.session),
        columns: %i[name postcode year_group select_for_matching]
      )
    end

    it { should have_column("Action") }
    it { should have_column("Postcode") }
    it { should_not have_link(patient_sessions.first.patient.full_name) }
  end

  context "when passing in patients" do
    let(:patients) { patient_sessions.map(&:patient) }

    let(:component) do
      described_class.new(params:, patients:, programme:, section:)
    end

    it { should have_css(".nhsuk-table") }
    it { should have_css(".nhsuk-table__head") }
    it { should have_column("Full name") }
    it { should have_column("Year group") }
    it { should have_css(".nhsuk-table__head .nhsuk-table__row", count: 1) }

    it "includes the patient's full name" do
      expect(rendered).to have_text(patients.first.full_name)
    end
  end

  context "when passing in patients and patient sessions" do
    let(:patients) { patient_sessions.map(&:patient) + [create(:patient)] }

    let(:component) do
      described_class.new(
        params:,
        patients:,
        patient_sessions:,
        programme:,
        section:
      )
    end

    it { should have_css(".nhsuk-table__body .nhsuk-table__row", count: 3) }
  end

  describe "vaccinations section" do
    let(:section) { :vaccination }
    let(:tab) { :actions }

    it do
      expect(rendered).to have_link(
        patient_sessions.first.patient.full_name,
        href: "/session/patient/"
      )
    end
  end

  describe "without a section or tab in the params" do
    let(:section) { :patients }
    let(:params) { { session_slug: session.slug } }

    shared_examples "guesses the path" do |status, section, tab|
      context "for #{status}" do
        let(:patient_sessions) do
          create_list(:patient_session, 1, status, session:, programme:)
        end

        it "guesses the path" do
          expect(component).to receive(:session_patient_programme_path).with(
            anything,
            anything,
            anything,
            section:,
            tab:
          )
          rendered
        end
      end
    end

    include_examples "guesses the path",
                     :added_to_session,
                     "consents",
                     "no-consent"
    include_examples "guesses the path", :consent_refused, "consents", "refused"
    include_examples "guesses the path",
                     :consent_conflicting,
                     "consents",
                     "conflicts"
    include_examples "guesses the path",
                     :consent_given_triage_needed,
                     "triage",
                     "needed"
    include_examples "guesses the path",
                     :triaged_kept_in_triage,
                     "triage",
                     "needed"
    include_examples "guesses the path",
                     :consent_given_triage_not_needed,
                     "vaccinations",
                     "vaccinate"
    include_examples "guesses the path",
                     :triaged_ready_to_vaccinate,
                     "vaccinations",
                     "vaccinate"
    include_examples "guesses the path",
                     :delay_vaccination,
                     "vaccinations",
                     "vaccinate"
    include_examples "guesses the path",
                     :triaged_do_not_vaccinate,
                     "vaccinations",
                     "could-not"
    include_examples "guesses the path",
                     :unable_to_vaccinate,
                     "vaccinations",
                     "could-not"
    include_examples "guesses the path",
                     :vaccinated,
                     "vaccinations",
                     "vaccinated"
  end

  describe "columns parameter" do
    context "is not set" do
      let(:component) do
        described_class.new(patient_sessions:, programme:, section:, params:)
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
