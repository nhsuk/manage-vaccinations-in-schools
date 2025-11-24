# frozen_string_literal: true

describe Stats::Vaccinations do
  describe "#call" do
    let(:programme_flu) { Programme.flu }
    let(:programme_hpv) { Programme.hpv }
    let(:programme_menacwy) { Programme.menacwy }

    let(:target_organisation) { create(:organisation, ods_code: "TARGET123") }
    let(:target_team) do
      create(:team, organisation: target_organisation, name: "Team Alpha")
    end
    let(:target_team2) do
      create(:team, organisation: target_organisation, name: "Team Beta")
    end

    let(:other_organisation) { create(:organisation, ods_code: "OTHER456") }
    let(:other_team) do
      create(:team, organisation: other_organisation, name: "TEAM999")
    end

    let(:target_patient_a) { create(:patient, team: target_team) }
    let(:target_patient_b) { create(:patient, team: target_team2) }
    let(:other_patient) { create(:patient, team: other_team) }

    let(:target_session_a) do
      create(
        :session,
        team: target_team,
        programmes: [programme_flu, programme_hpv]
      )
    end

    let(:target_session_b) do
      create(
        :session,
        team: target_team2,
        programmes: [programme_flu, programme_menacwy]
      )
    end

    let(:other_session) do
      create(:session, team: other_team, programmes: [programme_flu])
    end

    context "when comprehensive vaccination data exists" do
      before do
        create(
          :vaccination_record,
          patient: target_patient_a,
          programme: programme_flu,
          outcome: "administered",
          session: target_session_a
        )
        create(
          :vaccination_record,
          patient: target_patient_a,
          programme: programme_flu,
          outcome: "refused",
          session: target_session_a
        )
        create(
          :vaccination_record,
          patient: target_patient_a,
          programme: programme_hpv,
          outcome: "administered",
          session: target_session_a
        )

        create(
          :vaccination_record,
          patient: target_patient_b,
          programme: programme_flu,
          outcome: "administered",
          session: target_session_b
        )
        create(
          :vaccination_record,
          patient: target_patient_b,
          programme: programme_menacwy,
          outcome: "absent",
          session: target_session_b
        )

        create(
          :vaccination_record,
          patient: other_patient,
          programme: programme_flu,
          outcome: "administered",
          session: other_session
        )
        create(
          :vaccination_record,
          patient: other_patient,
          programme: programme_flu,
          outcome: "contraindicated",
          session: other_session
        )
      end

      it "returns counts grouped by programme and outcome" do
        result = described_class.call

        expect(result).to include("flu", "hpv", "menacwy")
        expect(result.dig("flu", "administered")).to eq(3)
        expect(result.dig("flu", "refused")).to eq(1)
        expect(result.dig("flu", "contraindicated")).to eq(1)
        expect(result.dig("hpv", "administered")).to eq(1)
        expect(result.dig("menacwy", "absent")).to eq(1)

        total_count = result.values.map(&:values).flatten.sum
        expect(total_count).to eq(7)
      end

      it "filters by teams" do
        result = described_class.call(teams: [target_team])

        expect(result).to include("flu", "hpv")
        expect(result).not_to include("menacwy")
        expect(result.dig("flu", "administered")).to eq(1)
        expect(result.dig("flu", "refused")).to eq(1)
        expect(result.dig("hpv", "administered")).to eq(1)

        total_count = result.values.map(&:values).flatten.sum
        expect(total_count).to eq(3)
      end

      it "filters by programme" do
        result = described_class.call(programme_type: "flu")

        expect(result).to include("flu")
        expect(result).not_to include("hpv", "menacwy")
        expect(result.dig("flu", "administered")).to eq(3)
        expect(result.dig("flu", "refused")).to eq(1)
        expect(result.dig("flu", "contraindicated")).to eq(1)

        total_count = result.values.map(&:values).flatten.sum
        expect(total_count).to eq(5)
      end

      it "filters by outcome" do
        result = described_class.call(outcome: "administered")

        expect(result.dig("flu", "administered")).to eq(3)
        expect(result.dig("hpv", "administered")).to eq(1)
        expect(result.keys).to contain_exactly("flu", "hpv")
        expect(
          result.values.all? { |outcomes| outcomes.keys == ["administered"] }
        ).to be true

        total_count = result.values.map(&:values).flatten.sum
        expect(total_count).to eq(4)
      end

      it "filters by date range" do
        old_session =
          create(:session, team: target_team, programmes: [programme_flu])
        create(
          :vaccination_record,
          patient: create(:patient, team: target_team),
          programme: programme_flu,
          outcome: "administered",
          session: old_session,
          created_at: 2.months.ago
        )

        result =
          described_class.call(since_date: 1.month.ago.strftime("%Y-%m-%d"))

        expect(result.dig("flu", "administered")).to eq(3)
      end

      it "combines multiple filters" do
        result =
          described_class.call(
            teams: [target_team],
            programme_type: "flu",
            outcome: "administered"
          )

        expect(result).to eq({ "flu" => { "administered" => 1 } })
      end
    end

    context "when no vaccination data exists" do
      it "returns empty hash" do
        result = described_class.call

        expect(result).to eq({})
      end
    end
  end
end
