# frozen_string_literal: true

describe Generate::CohortImports do
  before do
    team = create(:team, workgroup: "A9A5A")
    programme = create(:programme, :hpv)
    location =
      create(:school, :secondary, team:, name: "Test School", urn: "31337")
    create(:session, team:, slug: "slug", location:, programmes: [programme])
  end

  it "generates patients" do
    expect(described_class.new.patients.count).to eq 10
  end
end
