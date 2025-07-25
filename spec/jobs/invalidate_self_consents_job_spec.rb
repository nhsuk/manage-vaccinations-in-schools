# frozen_string_literal: true

describe InvalidateSelfConsentsJob do
  subject(:perform_now) { described_class.perform_now }

  context "with parental consent from yesterday" do
    let(:consent) { create(:consent, created_at: 1.day.ago) }

    it "does not invalidate the consent" do
      expect { perform_now }.not_to(change { consent.reload.invalidated? })
    end

    context "with triage" do
      let(:triage) do
        create(
          :triage,
          created_at: 1.day.ago,
          team: consent.team,
          programme: consent.programme,
          patient: consent.patient
        )
      end

      it "does not invalidate the triage" do
        expect { perform_now }.not_to(change { triage.reload.invalidated? })
      end
    end
  end

  context "with parental consent from today" do
    let(:consent) { create(:consent) }

    it "does not invalidate the consent" do
      expect { perform_now }.not_to(change { consent.reload.invalidated? })
    end

    context "with triage" do
      let(:triage) do
        create(
          :triage,
          team: consent.team,
          programme: consent.programme,
          patient: consent.patient
        )
      end

      it "does not invalidate the triage" do
        expect { perform_now }.not_to(change { triage.reload.invalidated? })
      end
    end
  end

  context "with self-consent from yesterday" do
    let(:consent) { create(:consent, :self_consent, created_at: 1.day.ago) }

    it "invalidates the consent" do
      expect { perform_now }.to change { consent.reload.invalidated? }.from(
        false
      ).to(true)
    end

    context "with triage" do
      let(:triage) do
        create(
          :triage,
          created_at: 1.day.ago,
          team: consent.team,
          programme: consent.programme,
          patient: consent.patient
        )
      end

      it "invalidates the triage" do
        expect { perform_now }.to change { triage.reload.invalidated? }.from(
          false
        ).to(true)
      end
    end
  end

  context "with self-consent from today" do
    let(:consent) { create(:consent, :self_consent) }

    it "does not invalidate the consent" do
      expect { perform_now }.not_to(change { consent.reload.invalidated? })
    end

    context "with triage" do
      let(:triage) do
        create(
          :triage,
          team: consent.team,
          programme: consent.programme,
          patient: consent.patient
        )
      end

      it "does not invalidate the triage" do
        expect { perform_now }.not_to(change { triage.reload.invalidated? })
      end
    end
  end

  context "with two programmes, parental consent for one and self-consent for the other" do
    let(:parent_programme) { create(:programme, :flu) }
    let(:self_programme) { create(:programme, :hpv) }

    let(:team) { create(:team, programmes: [parent_programme, self_programme]) }

    let(:patient) { create(:patient) }

    let!(:self_consent) do
      create(
        :consent,
        :self_consent,
        patient:,
        created_at: 1.day.ago,
        programme: self_programme,
        team:
      )
    end
    let!(:parent_consent) do
      create(
        :consent,
        patient:,
        created_at: 1.day.ago,
        programme: parent_programme,
        team:
      )
    end

    it "does not invalidate the parent consent" do
      expect { perform_now }.not_to(
        change { parent_consent.reload.invalidated? }
      )
    end

    it "invalidates the self-consent" do
      expect { perform_now }.to change {
        self_consent.reload.invalidated?
      }.from(false).to(true)
    end
  end
end
