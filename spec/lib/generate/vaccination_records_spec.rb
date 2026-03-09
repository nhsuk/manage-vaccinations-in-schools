# frozen_string_literal: true

describe Generate::VaccinationRecords do
  let(:programme) { Programme.hpv }
  let(:team) { create(:team, programmes: [programme]) }
  let(:session) { create(:session, team:, programmes: [programme]) }
  let(:user) { create(:user, team:) }
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
      create_list(
        :patient,
        10,
        :consent_given_triage_not_needed,
        programmes: [programme],
        session:
      )

      described_class.call(team:, administered: 1)
      expect(VaccinationRecord.administered.count).to eq 1
    end

    describe "with a session" do
      it "creates a vaccination record for the session" do
        user
        patient

        described_class.call(team:, session:, administered: 1)
        expect(session.reload.vaccination_records.administered.count).to eq 1
      end

      context "session has no dates" do
        it "raises an error" do
          session.update!(dates: [])

          expect {
            described_class.call(team:, session:, administered: 1)
          }.to raise_error(Generate::VaccinationRecords::SessionHasNoDates)
        end
      end
    end

    describe "without a session argument" do
      it "uses sample to select a random session" do
        user
        patient

        sessions = [session]
        allow(sessions).to receive(:sample).and_return(session)

        generator = described_class.send(:new, team:, administered: 1)
        allow(described_class).to receive(:new).and_return(generator)
        allow(generator).to receive(:sessions).and_return(sessions)

        described_class.call(team:, administered: 1)

        expect(sessions).to have_received(:sample)
      end
    end

    context "no sessions with dates" do
      it "raises an error" do
        session.update!(dates: [])

        expect { described_class.call(team:, administered: 1) }.to raise_error(
          Generate::VaccinationRecords::NoSessionsWithDates
        )
      end
    end

    context "no patients without vaccinations" do
      it "raises an error" do
        session

        expect { described_class.call(team:, administered: 1) }.to raise_error(
          Generate::VaccinationRecords::NoSessionsWithPatients
        )
      end
    end
  end
end
