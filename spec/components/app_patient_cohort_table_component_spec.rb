# frozen_string_literal: true

describe AppPatientCohortTableComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient, current_user:) }

  let(:current_user) { create(:nurse) }

  context "without a cohort" do
    let(:patient) { create(:patient) }

    it { should have_content("No cohorts") }
  end

  context "with a cohort" do
    let(:team) { current_user.selected_team }
    let(:session) { create(:session, team:) }

    let(:patient) { create(:patient, year_group: 8, session:) }

    it { should have_content("Year 8") }
    it { should have_content("Remove from cohort") }
  end
end
