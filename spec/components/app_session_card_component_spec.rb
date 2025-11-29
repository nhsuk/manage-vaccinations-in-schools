# frozen_string_literal: true

describe AppSessionCardComponent do
  subject(:rendered) { travel_to(today) { render_inline(component) } }

  let(:component) { described_class.new(session, patient_count: 100) }

  let(:today) { Date.new(2025, 7, 1) }

  let(:programme) { Programme.flu }
  let(:date) { Date.new(2025, 9, 1) }

  let(:session) do
    create(:session, academic_year: 2025, date:, programmes: [programme])
  end

  it { should have_text("Cohort100 children") }
  it { should have_text("ProgrammesFlu") }
  it { should have_text("StatusScheduled") }
  it { should have_text("Session dates1 September 2025") }
  it { should have_text("Consent periodOpens 11 August") }
end
