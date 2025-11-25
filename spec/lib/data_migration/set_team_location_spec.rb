# frozen_string_literal: true

describe DataMigration::SetTeamLocation do
  subject(:call) { described_class.call }

  let(:team) { create(:team) }
  let(:location) { create(:school) }
  let(:academic_year) { AcademicYear.current }

  context "with a consent form" do
    let(:consent_form) do
      create(
        :consent_form,
        team:,
        location:,
        academic_year:,
        team_location: nil
      )
    end

    it "sets the team location" do
      expect { call }.to change { consent_form.reload.team_location }.from(nil)

      team_location = consent_form.team_location
      expect(team_location.team).to eq(team)
      expect(team_location.location).to eq(location)
      expect(team_location.academic_year).to eq(academic_year)
    end
  end

  context "with a session" do
    let(:session) do
      create(:session, team:, location:, academic_year:, team_location: nil)
    end

    it "sets the team location" do
      expect { call }.to change { session.reload.team_location }.from(nil)

      team_location = session.team_location
      expect(team_location.team).to eq(team)
      expect(team_location.location).to eq(location)
      expect(team_location.academic_year).to eq(academic_year)
    end
  end
end
