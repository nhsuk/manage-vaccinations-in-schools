# frozen_string_literal: true

describe AppSessionSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(session) }

  let(:programme) { create(:programme, :hpv) }
  let(:location) { create(:location, :school) }
  let(:session) do
    create(:session, location:, date: Date.new(2024, 1, 1), programme:)
  end

  it { should have_content("Type") }
  it { should have_content("School session") }

  context "with a clinic" do
    let(:location) { create(:location, :clinic) }

    it { should have_content("Community clinic") }
  end

  it { should have_content("Programmes") }
  it { should have_content("HPV") }

  it { should have_content("Session dates") }
  it { should have_content("1 January 2024") }

  it { should have_content("Consent period") }
  it { should have_content("Closed 31 December") }

  it { should_not have_content("Consent link") }

  it { should have_content("Children") }
  it { should have_content("No children") }

  context "when consent is open" do
    let(:session) do
      create(:session, location:, date: 1.week.from_now.to_date, programme:)
    end

    it { should have_content("Consent link") }
    it { should have_link("View parental consent form (opens in a new tab)") }
  end
end
