# frozen_string_literal: true

describe Generate::VaccinationRecords do
  let(:programme) { Programme.hpv&.first || create(:programme, :hpv) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:session) { create(:session, organisation:, programmes: [programme]) }
  let(:user) { create(:user, organisation:) }
  let(:patient) do
    create(
      :patient,
      :consent_given_triage_not_needed,
      programmes: [programme],
      session:
    )
  end

  describe "vaccinations administered" do
    subject(:vaccinations_given) { VaccinationRecord.administered }

    it "creates one vaccination record" do
      user
      patient

      described_class.call(organisation:, administered: 1)
      expect(VaccinationRecord.administered.count).to eq 1
    end

    describe "with a session" do
      it "creates a vaccination record for the session" do
        user
        patient

        described_class.call(organisation:, session:, administered: 1)
        expect(session.reload.vaccination_records.administered.count).to eq 1
      end
    end

    context "no patients without vaccinations" do
      it "raises an error" do
        expect {
          described_class.call(organisation:, administered: 1)
        }.to raise_error(RuntimeError)
      end
    end
  end
end
