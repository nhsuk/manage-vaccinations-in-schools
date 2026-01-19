# frozen_string_literal: true

describe NextDoseTriageFactory do
  subject(:call) { described_class.call(vaccination_record:) }

  let(:vaccination_record) { create(:vaccination_record, programme:) }

  context "with a single dose programme" do
    let(:programme) { Programme.hpv }

    it "does not create a triage" do
      expect { call }.not_to(change(Triage, :count))
    end
  end

  context "with the MMR programme" do
    let(:programme) { Programme.mmr }

    it "creates a triage" do
      expect { call }.to change(Triage, :count).by(1)

      triage = vaccination_record.reload.next_dose_delay_triage
      expect(triage).to be_delay_vaccination
      expect(triage.delay_vaccination_until).to eq(28.days.from_now.to_date)
      expect(triage.disease_types).to be_empty
      expect(triage.performed_by).to be_nil
      expect(triage.programme_type).to eq("mmr")
      expect(triage.team).to be_nil
    end

    context "when performed over 28 days ago" do
      let(:vaccination_record) do
        create(:vaccination_record, programme:, performed_at: 29.days.ago)
      end

      it "does not create a triage" do
        expect { call }.not_to(change(Triage, :count))
      end
    end

    context "when it is an invalid second MMR dose (too early)" do
      let(:patient) do
        create(
          :patient,
          :consent_given_triage_safe_to_vaccinate,
          year_group: 9,
          session:
        )
      end
      let(:session) { create(:session, programmes: [programme]) }

      it "shows delay vaccination 28 days after last vaccine" do
        create(
          :vaccination_record,
          programme:,
          patient:,
          session:,
          performed_at: 20.days.ago
        )
        second_dose =
          create(:vaccination_record, programme:, session:, patient:)

        StatusUpdater.call(patient:)

        described_class.call(vaccination_record: second_dose.reload)

        triage = second_dose.reload.next_dose_delay_triage

        expect(triage.delay_vaccination_until).to eq(28.days.from_now.to_date)
      end
    end

    context "when a next dose triage record already exists" do
      let(:vaccination_record) do
        create(:vaccination_record, :administered, programme:)
      end

      before { described_class.call(vaccination_record:) }

      it "does not create another triage record" do
        expect { call }.not_to change(Triage, :count)
      end
    end
  end
end
