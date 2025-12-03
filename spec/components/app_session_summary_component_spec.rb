# frozen_string_literal: true

describe AppSessionSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(session) }

  let(:programmes) { [Programme.hpv] }
  let(:location) do
    create(
      :school,
      :secondary,
      name: "Streeling University",
      urn: 123_456,
      address_postcode: "SW1A 1AA",
      programmes:
    )
  end
  let(:team) { create(:team, programmes:) }
  let(:session) { create(:session, location:, programmes:, team:) }

  it { should have_content("ProgrammesHPV") }
  it { should have_content("Year groupsYears 8, 9, 10, and 11") }
end
