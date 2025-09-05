# frozen_string_literal: true

describe AppProgrammeSessionTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(sessions, programme:) }

  let(:programme) { create(:programme) }
  let(:location) do
    create(:school, name: "Waterloo Road", programmes: [programme])
  end
  let(:session) { create(:session, programmes: [programme], location:) }
  let(:sessions) do
    [session] + create_list(:session, 2, programmes: [programme])
  end
  let(:patient) { create(:patient, session:) }

  before do
    create_list(:patient_session, 4, :consent_no_response, session:)

    create(:patient_consent_status, :given, programme:, patient:)

    create(:vaccination_record, patient:, session:, programme:)
  end

  it { should have_content("3 sessions") }

  it do
    expect(rendered).to have_content(
      "DetailsCohortNo responseTriage neededVaccinated"
    )
  end

  it { should have_content("Waterloo Road") }
  it { should have_content(/Cohort(\s+)5/) }
  it { should have_content(/No response(\s+)4(\s+)80%/) }
  it { should have_content(/Vaccinated(\s+)1(\s+)20%/) }

  context "when the patient is not eligible for the programme" do
    let(:programme) { create(:programme, :hpv) }
    let(:patient) { create(:patient, session:, year_group: 7) }

    it { should have_content(/Cohort(\s+)4/) }
    it { should have_content(/No response(\s+)4(\s+)100%/) }
  end
end
