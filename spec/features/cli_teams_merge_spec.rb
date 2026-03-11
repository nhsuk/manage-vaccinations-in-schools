# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis teams merge" do
  let(:organisation) { create(:organisation) }

  let!(:team_a) do
    create(
      :team,
      organisation:,
      workgroup: "team-a",
      name: "Team A",
      programmes: [Programme.hpv]
    )
  end

  let!(:team_b) do
    create(
      :team,
      organisation:,
      workgroup: "team-b",
      name: "Team B",
      programmes: [Programme.flu]
    )
  end

  def merge_command(**overrides)
    defaults = {
      workgroups: %w[team-a team-b],
      name: "Team Combined",
      workgroup: "team-combined"
    }
    opts = defaults.merge(overrides)
    args = [
      "teams",
      "merge",
      *opts[:workgroups],
      "--name=#{opts[:name]}",
      "--workgroup=#{opts[:workgroup]}",
      "--email=combined@example.com",
      "--phone=01234 567890",
      "--privacy-notice-url=https://example.com/privacy-notice",
      "--privacy-policy-url=https://example.com/privacy-policy"
    ]
    args << "--dry-run" if opts[:dry_run]
    Dry::CLI.new(MavisCLI).call(arguments: args)
  end

  context "happy path — two compatible teams" do
    it "creates merged team, migrates records, and deletes source teams" do
      consent = create(:consent, team: team_a)
      cohort_import = create(:cohort_import, team: team_b)

      capture_output { merge_command }

      expect(Team.find_by(workgroup: "team-combined")).to be_present
      expect(Team.find_by(workgroup: "team-a")).to be_nil
      expect(Team.find_by(workgroup: "team-b")).to be_nil

      merged = Team.find_by(workgroup: "team-combined")
      expect(merged.programme_types).to match_array(%w[flu hpv])

      expect(consent.reload.team).to eq(merged)
      expect(cohort_import.reload.team).to eq(merged)
    end
  end

  context "with --dry-run" do
    it "prints the migration plan and makes no DB changes" do
      create(:consent, team: team_a)

      output = capture_output { merge_command(dry_run: true) }

      expect(output).to include("consents: 1 row(s) to migrate")
      expect(output).to include("Merge would succeed.")

      expect(Team.find_by(workgroup: "team-a")).to be_present
      expect(Team.find_by(workgroup: "team-b")).to be_present
      expect(Team.find_by(workgroup: "team-combined")).to be_nil
    end
  end

  context "patient present in both source teams" do
    it "merges sources arrays in patient_teams" do
      patient = create(:patient)
      create(
        :patient_team,
        team: team_a,
        patient:,
        sources: %i[patient_location]
      )
      create(
        :patient_team,
        team: team_b,
        patient:,
        sources: %i[vaccination_record_session]
      )

      capture_output { merge_command }

      merged = Team.find_by(workgroup: "team-combined")
      pt = PatientTeam.find_by(team: merged, patient:)
      expect(pt.sources).to include(
        "patient_location",
        "vaccination_record_session"
      )
    end
  end

  context "duplicate subteam name across source teams" do
    it "aborts with error message" do
      create(:subteam, team: team_a, name: "Admin")
      create(:subteam, team: team_b, name: "Admin")

      output = capture_error { merge_command }

      expect(output).to include(
        "Subteam 'Admin' exists in multiple source teams"
      )
      expect(Team.find_by(workgroup: "team-combined")).to be_nil
    end
  end

  context "duplicate batch across source teams" do
    it "skips the duplicate and completes successfully" do
      vaccine = Programme.flu.vaccines.first
      create(
        :batch,
        team: team_a,
        vaccine:,
        number: "AB1234",
        expiry: Date.new(2026, 1, 1)
      )
      create(
        :batch,
        team: team_b,
        vaccine:,
        number: "AB1234",
        expiry: Date.new(2026, 1, 1)
      )

      capture_output { merge_command }

      merged = Team.find_by(workgroup: "team-combined")
      expect(merged).to be_present
      matching_batches =
        Batch.where(
          team: merged,
          number: "AB1234",
          expiry: Date.new(2026, 1, 1),
          vaccine:
        )
      expect(matching_batches.count).to eq(1)
    end
  end

  context "conflicting team_location (same location, different subteams)" do
    it "aborts with error message" do
      location = create(:school, :secondary)
      subteam_a = create(:subteam, team: team_a, name: "Sub A")
      subteam_b = create(:subteam, team: team_b, name: "Sub B")
      academic_year = AcademicYear.current
      create(
        :team_location,
        team: team_a,
        location:,
        academic_year:,
        subteam: subteam_a
      )
      create(
        :team_location,
        team: team_b,
        location:,
        academic_year:,
        subteam: subteam_b
      )

      output = capture_error { merge_command }

      expect(output).to include(
        "assigned to different subteams across source teams"
      )
      expect(Team.find_by(workgroup: "team-combined")).to be_nil
    end
  end

  context "teams from different organisations" do
    it "aborts with error message" do
      other_org = create(:organisation)
      team_b.update_column(:organisation_id, other_org.id)

      output = capture_error { merge_command }

      expect(output).to include("different organisations")
      expect(Team.find_by(workgroup: "team-combined")).to be_nil
    end
  end

  context "teams of different types" do
    it "aborts with error message" do
      team_b.update_column(:type, Team.types[:national_reporting])
      team_b.update_columns(
        email: nil,
        phone: nil,
        privacy_notice_url: nil,
        privacy_policy_url: nil
      )

      output =
        capture_error do
          Dry::CLI.new(MavisCLI).call(
            arguments: [
              "teams",
              "merge",
              "team-a",
              "team-b",
              "--name=Team Combined",
              "--workgroup=team-combined"
            ]
          )
        end

      expect(output).to include("different types")
    end
  end

  context "unknown workgroup" do
    it "aborts with error message" do
      output =
        capture_error do
          Dry::CLI.new(MavisCLI).call(
            arguments: %w[
              teams
              merge
              team-a
              nonexistent-wg
              --name=Team
              Combined
              --workgroup=team-combined
              --email=combined@nhs.net
              --phone=01234\ 567890
              --privacy-notice-url=https://example.com/privacy-notice
              --privacy-policy-url=https://example.com/privacy-policy
            ]
          )
        end

      expect(output).to include(
        "Could not find team with workgroup 'nonexistent-wg'."
      )
      expect(Team.find_by(workgroup: "team-combined")).to be_nil
    end
  end
end
