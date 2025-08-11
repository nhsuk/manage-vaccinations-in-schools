# frozen_string_literal: true

describe TeamMigration::Leicestershire do
  subject(:call) { described_class.call }

  let!(:flu_programme) { create(:programme, :flu) }
  let!(:hpv_programme) { create(:programme, :hpv) }

  let(:organisation) { create(:organisation, ods_code: "RT5") }
  let(:team) { create(:team, organisation:, programmes: [hpv_programme]) }

  let!(:existing_school) { create(:school, team:) }
  let!(:new_schools) do
    described_class::SEN_SCHOOL_URNS.map { |urn| create(:school, urn:) }
  end

  it "sets the workgroup" do
    expect { call }.to change { team.reload.workgroup }.to("leicestershiresais")
  end

  it "adds the flu programme" do
    expect { call }.to change { team.reload.programmes.count }.from(1).to(2)
    expect(team.programmes).to include(flu_programme)

    generic_clinic = team.locations.generic_clinic.first
    expect(generic_clinic.year_groups).to eq(
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    )
    expect(generic_clinic.programmes).to include(flu_programme)
  end

  it "adds the schools to the team with flu and HPV" do
    expect { call }.to change { team.reload.schools.count }.by(30)

    new_schools.each do |school|
      expect(school.programmes).to contain_exactly(hpv_programme, flu_programme)
    end
  end

  it "adds flu to existing schools" do
    expect { call }.to change {
      existing_school.reload.location_programme_year_groups.count
    }.by(12)
  end
end
