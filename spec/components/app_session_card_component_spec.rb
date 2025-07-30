# frozen_string_literal: true

describe AppSessionCardComponent do
  subject { render_inline(component) }

  let(:component) do
    travel_to(today) { described_class.new(session, patient_count: 100) }
  end

  let(:today) { Date.new(2025, 7, 1) }

  let(:programme) { create(:programme, :flu) }
  let(:date) { Date.new(2025, 9, 1) }

  let(:session) do
    create(:session, academic_year: 2025, date:, programmes: [programme])
  end

  it { should have_text("Cohort\n100 children") }
  it { should have_text("Programmes\nFlu") }
  it { should have_text("Status\nSessions scheduled") }
  it { should have_text("Session dates\nMonday, 1 September 2025") }
  it { should have_text("Consent period\nOpens 11 August") }
end
