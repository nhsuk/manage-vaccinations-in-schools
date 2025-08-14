# frozen_string_literal: true

describe TeamMigration::EastOfEngland do
  subject(:call) { described_class.call }

  let!(:flu_programme) { create(:programme, :flu) }
  let!(:hpv_programme) { create(:programme, :hpv) }

  let(:organisation) { create(:organisation, ods_code: "RY4") }
  let!(:current_team) do
    create(
      :team,
      :with_generic_clinic,
      name:
        "Hertfordshire and East Anglia Community School Age Immunisation Service",
      organisation:,
      programmes: [hpv_programme]
    )
  end

  let(:csv_data) { <<-CSV }
URN,SEN,ICB Shortname
109464,,BLMK ICB
135990,SEN,BLMK ICB
136083,,C&P ICB
148249,SEN,C&P ICB
141380,,HWE ICB
148008,SEN,HWE ICB
133312,,MSE ICB
150238,SEN,MSE ICB
110643,,N&W ICB
135066,SEN,N&W ICB
115203,,SNEE ICB
147473,SEN,SNEE ICB
  CSV

  before do
    parsed_csv_data = CSV.parse(csv_data, headers: true)

    allow(CSV).to receive(:foreach).and_return(parsed_csv_data)

    parsed_csv_data.each do |row|
      create(
        :school,
        urn: row.fetch("URN"),
        team: current_team,
        year_groups: (0..14).to_a
      )
    end
  end

  it "doesn't destroy any schools" do
    expect { call }.not_to change(Location.school, :count)
  end

  it "creates six new teams with flu programme and destroys original" do
    expect { call }.to change(organisation.teams, :count).by(5)

    organisation
      .teams
      .includes(:programmes, :schools)
      .find_each do |team|
        expect(team.programmes).to contain_exactly(flu_programme, hpv_programme)

        generic_clinic = team.locations.generic_clinic.first
        expect(generic_clinic.year_groups).to eq(
          [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        )
        expect(generic_clinic.programmes).to include(flu_programme)

        expect(team.schools.count).to eq(2)

        mainstream_school = team.schools.order(:created_at).first
        sen_school = team.schools.order(:created_at).last

        expect(mainstream_school.programmes).to contain_exactly(hpv_programme)
        expect(mainstream_school.programme_year_groups[hpv_programme]).to eq(
          [8, 9, 10, 11]
        )

        expect(sen_school.programmes).to contain_exactly(
          flu_programme,
          hpv_programme
        )
        expect(sen_school.programme_year_groups[hpv_programme]).to eq(
          [8, 9, 10, 11]
        )
        expect(sen_school.programme_year_groups[flu_programme]).to eq(
          [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        )
      end

    expect { current_team.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  context "with patients in community clinic" do
    let(:current_session) do
      current_team.generic_clinic_session(academic_year: AcademicYear.current)
    end

    let(:school) { Location.school.first }

    let!(:unknown_school_patient) do
      create(:patient, session: current_session, school: nil)
    end
    let!(:known_school_patient) do
      create(:patient, session: current_session, school:)
    end

    it "moves patients in to the relevant community clinics" do
      expect { call }.to change(PatientSession, :count).by(-1)

      expect(unknown_school_patient.sessions).to be_empty

      new_session =
        school.reload.team.generic_clinic_session(
          academic_year: AcademicYear.current
        )
      expect(known_school_patient.sessions).to include(new_session)
    end
  end
end
