# frozen_string_literal: true

describe Generate::CohortImports do
  subject(:cohort_imports) { described_class.new(team:, programme:) }

  let(:programme) { create(:programme, :hpv) }
  let(:team) { create(:team, programmes: [programme]) }

  before do
    location =
      create(:school, :secondary, team:, name: "Test School", urn: "31337")
    create(:session, team:, slug: "slug", location:, programmes: [programme])
  end

  it "generates patients" do
    expect(cohort_imports.patients.count).to eq 10
  end
end
