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

  it { should have_text("Children100 children") }
  it { should have_text("ProgrammesFlu") }

  it do
    expect(rendered).to have_text(
      "Year groupsReception, Years 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, and 11"
    )
  end

  it { should have_text("Date1 September 2025") }
  it { should have_text("Consent periodOpens 11 August") }

  it { should_not have_text("Status") }

  context "when showing status" do
    let(:component) do
      described_class.new(session, patient_count: 100, show_status: true)
    end

    it { should have_text("StatusScheduled") }
  end
end
