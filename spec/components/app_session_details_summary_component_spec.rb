# frozen_string_literal: true

describe AppSessionDetailsSummaryComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(session) }

  let(:programme) { CachedProgramme.hpv }
  let(:session) { create(:session, programmes: [programme]) }

  it { should have_text("CohortNo children") }
  it { should have_text("Consent refusedNo children") }
  it { should have_text("VaccinatedNo vaccinations given for HPV") }

  context "with activity" do
    before do
      create(:patient, session:)
      create(:patient, :consent_refused, session:)
      create(:patient, :vaccinated, session:)
    end

    it { should have_text("Cohort3 children") }
    it { should have_text("Consent refused1 child") }
    it { should have_text("Vaccinated1 vaccination given for HPV") }
    it { should have_link("Review consent refused") }
    it { should have_link("Review vaccinated") }
  end

  context "when the patients are not eligible for the programme" do
    before do
      create(:patient, session:, year_group: 7)
      create(:patient, :consent_refused, session:, year_group: 7)
    end

    it { should have_text("CohortNo children") }
    it { should have_text("Consent refusedNo children") }
  end
end
