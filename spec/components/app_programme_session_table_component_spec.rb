# frozen_string_literal: true

describe AppProgrammeSessionTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(sessions) }

  let(:programme) { create(:programme) }

  let(:location) { create(:location, :school, name: "Waterloo Road") }

  let(:session) { create(:session, programme:, location:) }

  let(:sessions) { [session] + create_list(:session, 2, programme:) }

  let(:patient_session) { create(:patient_session, session:) }

  before do
    create_list(:patient_session, 4, session:)

    create(
      :consent,
      :given,
      :recorded,
      programme:,
      patient: patient_session.patient
    )
    create(:vaccination_record, programme:, patient_session:)
  end

  it { should have_content("3 sessions") }

  it do
    expect(rendered).to have_content(
      "Details\nCohort\nNo response\nTriage needed\nVaccinated"
    )
  end

  it { should have_content("Waterloo Road") }
  it { should have_content(/Cohort(\s+)5/) }
  it { should have_content(/No response(\s+)4(\s+)80%/) }
  it { should have_content(/Vaccinated(\s+)1(\s+)20%/) }
end
