# frozen_string_literal: true

describe AppSchoolCardComponent do
  subject(:rendered) { travel_to(today) { render_inline(component) } }

  let(:component) do
    described_class.new(school, patient_count: 100, next_session_date: today)
  end

  let(:today) { Date.new(2025, 7, 1) }

  let(:school) do
    create(:school, :secondary, urn: "123456", address_line_1: "Waterloo Road")
  end

  it { should have_text("Children100 children") }
  it { should have_text("URN123456") }
  it { should have_text("PhaseSecondary") }
  it { should have_text("AddressWaterloo Road") }
  it { should have_text("Next session1 July 2025") }
end
