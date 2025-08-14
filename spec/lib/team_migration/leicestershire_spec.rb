# frozen_string_literal: true

describe TeamMigration::Leicestershire do
  subject(:call) { described_class.call }

  let!(:flu_programme) { create(:programme, :flu) }
  let!(:hpv_programme) { create(:programme, :hpv) }

  let(:organisation) { create(:organisation, ods_code: "RT5") }
  let(:team) { create(:team, organisation:, programmes: [hpv_programme]) }

  let(:csv_data) { <<-CSV }
URN,SEN
119903
120330,SEN
    CSV

  before do
    parsed_csv_data = CSV.parse(csv_data, headers: true)

    allow(CSV).to receive(:foreach).and_return(parsed_csv_data)

    parsed_csv_data.each do |row|
      create(:school, urn: row.fetch("URN"), year_groups: (0..14).to_a)
    end
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

  it "adds schools to the team" do
    expect { call }.to change(team.schools, :count).by(2)

    mainstream_school = team.schools.order(:created_at).first
    sen_school = team.schools.order(:created_at).last

    expect(mainstream_school.programme_year_groups[hpv_programme]).to eq(
      [8, 9, 10, 11]
    )
    expect(mainstream_school.programme_year_groups[flu_programme]).to eq(
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    )

    expect(sen_school.programme_year_groups[hpv_programme]).to eq(
      [8, 9, 10, 11]
    )
    expect(sen_school.programme_year_groups[flu_programme]).to eq(
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    )
  end
end
