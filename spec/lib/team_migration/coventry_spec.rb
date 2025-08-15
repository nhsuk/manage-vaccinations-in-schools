# frozen_string_literal: true

describe TeamMigration::Coventry do
  subject(:call) { described_class.call }

  let!(:flu_programme) { create(:programme, :flu) }
  let!(:hpv_programme) { create(:programme, :hpv) }
  let!(:menacwy_programme) { create(:programme, :menacwy) }
  let!(:td_ipv_programme) { create(:programme, :td_ipv) }

  let(:organisation) { create(:organisation, ods_code: "RYG") }
  let(:team) do
    create(
      :team,
      :with_generic_clinic,
      organisation:,
      programmes: [hpv_programme, menacwy_programme, td_ipv_programme]
    )
  end

  let!(:subteams) do
    described_class::SUBTEAMS.values.map do |name|
      create(:subteam, name:, team:)
    end
  end

  let!(:school_to_remove) { create(:school, urn: "131574", team:) }

  let(:csv_data) { <<-CSV }
URN,Subteam,SEN
103639,COV,
103760,COV,SEN
125500,N WARKS,
125794,N WARKS,SEN
125507,S WARKS,
145486,S WARKS,SEN
  CSV

  before do
    parsed_csv_data = CSV.parse(csv_data, headers: true)

    allow(CSV).to receive(:foreach).and_return(parsed_csv_data)

    parsed_csv_data.each do |row|
      create(:school, urn: row.fetch("URN"), year_groups: (0..14).to_a)
    end
  end

  it "sets the workgroup" do
    expect { call }.to change { team.reload.workgroup }.to(
      "coventrywarwickshiresais"
    )
  end

  it "adds the flu programme" do
    expect { call }.to change { team.reload.programmes.count }.from(3).to(4)
    expect(team.programmes).to include(flu_programme)

    generic_clinic = team.locations.generic_clinic.first
    expect(generic_clinic.year_groups).to eq(
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    )
    expect(generic_clinic.programmes).to include(flu_programme)
  end

  it "adds schools to the subteams" do
    expect { call }.to change(team.schools, :count).by(6 - 1)

    subteams.each do |subteam|
      mainstream_school = subteam.schools.order(:created_at).first
      sen_school = subteam.schools.order(:created_at).last

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

  it "removes the closing school" do
    expect { call }.to change(team.schools, :count).by(6 - 1)

    expect(school_to_remove.reload.subteam).to be_nil
  end
end
