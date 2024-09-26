# frozen_string_literal: true

describe AppSessionTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(sessions) }

  let(:sessions) do
    [
      create(
        :session,
        academic_year: 2024,
        date: Date.new(2024, 10, 1),
        location: create(:location, :school, name: "Waterloo Road"),
        programme: create(:programme, :hpv)
      )
    ] + create_list(:session, 9)
  end

  before { create_list(:patient, 5, session: sessions.first) }

  it { should have_css(".nhsuk-table__heading-tab", text: "10 sessions") }

  context "with a custom description" do
    let(:component) do
      described_class.new(sessions, heading: "10 active sessions")
    end

    it { should have_content("10 active sessions") }
  end

  it "renders the headers" do
    expect(rendered).to have_css(".nhsuk-table__header", text: "Location")
    expect(rendered).to have_css(".nhsuk-table__header", text: "Children")
  end

  it "renders the rows" do
    expect(rendered).to have_css(
      ".nhsuk-table__body .nhsuk-table__row",
      count: 10
    )

    expect(rendered).to have_css(".nhsuk-table__cell", text: "Waterloo Road")

    expect(rendered).to have_css(".nhsuk-table__cell", text: "5")
    expect(rendered).to have_css(".nhsuk-table__cell", text: "None")
  end

  context "when showing dates" do
    let(:component) { described_class.new(sessions, show_dates: true) }

    it { should have_css(".nhsuk-table__header", text: "Dates") }
    it { should have_css(".nhsuk-table__cell", text: "1 October 2024") }
  end

  context "when showing programmes" do
    let(:component) { described_class.new(sessions, show_programmes: true) }

    it { should have_css(".nhsuk-table__header", text: "Programmes") }
    it { should have_css(".nhsuk-table__cell", text: "HPV") }
  end

  context "when showing consent period" do
    let(:component) { described_class.new(sessions, show_consent_period: true) }

    it { should have_css(".nhsuk-table__header", text: "Consent period") }
    it { should have_css(".nhsuk-table__cell", text: "Open until 1 October") }
  end
end
