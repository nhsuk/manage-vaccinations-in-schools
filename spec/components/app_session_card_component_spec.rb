# frozen_string_literal: true

describe AppSessionCardComponent do
  subject(:rendered) { travel_to(today) { render_inline(component) } }

  let(:component) { described_class.new(session, patient_count: 100) }

  let(:today) { Date.new(2025, 7, 1) }

  let(:programme) { create(:programme, :flu) }
  let(:date) { Date.new(2025, 9, 1) }

  let(:session) do
    create(:session, academic_year: 2025, date:, programmes: [programme])
  end

  it { should have_text("Cohort\n100 children") }
  it { should have_text("Programmes\nFlu") }
  it { should have_text("Status\nSessions scheduled") }
  it { should have_text("Session dates\n1 September 2025") }
  it { should have_text("Consent period\nOpens 11 August") }

  context "with no dates" do
    let(:session) do
      create(:session, academic_year: 2025, date: nil, programmes: [programme])
    end

    it { should have_text("Session dates\nNo sessions scheduled") }
  end

  context "with multiple dates" do
    let(:session) do
      create(
        :session,
        academic_year: 2025,
        dates: [date, date + 1.week, date + 2.weeks],
        programmes: [programme]
      )
    end

    it do
      expect(rendered).to have_text(
        "Session dates\n1 September 2025 – 15 September 2025 (3 sessions)"
      )
    end
  end
end
