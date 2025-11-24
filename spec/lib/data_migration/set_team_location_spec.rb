# frozen_string_literal: true

describe DataMigration::SetTeamLocation do
  subject(:call) { described_class.call }

  let(:team) { create(:team) }
  let(:school_subteam) { create(:subteam, team:) }
  let(:clinic_subteam) { create(:subteam, team:) }
  let!(:school_location) { create(:school, subteam: school_subteam) }
  let!(:clinic_location) { create(:generic_clinic, subteam: clinic_subteam) }

  it "creates team location instances" do
    expect { call }.to change(TeamLocation, :count).by(2)

    school_team_location =
      TeamLocation.find_by!(team:, location: school_location)
    expect(school_team_location.academic_year).to eq(AcademicYear.current)
    expect(school_team_location.subteam).to eq(school_subteam)

    clinic_team_location =
      TeamLocation.find_by!(team:, location: clinic_location)
    expect(clinic_team_location.academic_year).to eq(AcademicYear.current)
    expect(clinic_team_location.subteam).to be_nil
  end
end
