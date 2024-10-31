# frozen_string_literal: true

describe AppPatientCohortTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient) }

  context "without a cohort" do
    let(:patient) { create(:patient, cohort: nil) }

    it { should have_content("No cohorts") }
  end

  context "with a cohort" do
    let(:cohort) { create(:cohort, year_group: 8) }
    let(:patient) { create(:patient, cohort:) }

    it { should have_content("Year 8") }
    it { should have_content("Remove from cohort") }
  end
end
