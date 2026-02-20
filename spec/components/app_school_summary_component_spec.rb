# frozen_string_literal: true

describe AppSchoolSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(school, change_links:) }

  let(:programmes) { [Programme.hpv] }
  let(:school) do
    create(
      :school,
      :secondary,
      name: "Streeling University",
      urn: 123_456,
      address_line_1: "10 Downing Street",
      address_line_2: "Example Way",
      address_postcode: "SW1A 1AA",
      address_town: "London",
      gias_year_groups: [7, 8, 9, 10, 11],
      programmes:
    )
  end
  let(:team) { create(:team, programmes:) }
  let(:change_links) { {} }

  it { should have_content("ProgrammesHPV") }
  it { should have_content("Year groupsYears 7 to 11") }

  it { should have_content("Name") }
  it { should have_content("SW1A 1AA") }

  it { should have_content("URN") }
  it { should have_content("123456") }

  it { should have_content("Phase") }
  it { should have_content("Secondary") }

  it { should have_content("Address") }
  it { should have_content("10 Downing Street, Example Way, London, SW1A 1AA") }

  context "when there are change links" do
    let(:change_links) { { name: "/name", address: "/address" } }
    let(:component) { described_class.new(school, change_links:) }

    it { should have_link("Change name") }
    it { should have_link("Change address") }
  end
end
