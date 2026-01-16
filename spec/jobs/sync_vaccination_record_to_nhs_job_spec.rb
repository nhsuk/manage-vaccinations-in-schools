# frozen_string_literal: true

describe SyncVaccinationRecordToNHSJob, type: :job do
  subject(:perform) { described_class.new.perform(vaccination_record.id) }

  before { allow(NHS::ImmunisationsAPI).to receive(:sync_immunisation) }

  after { Flipper.disable(:imms_api_sync_job) }

  let(:programme) { Programme.flu }
  let(:vaccination_record) { create(:vaccination_record, programme:) }

  context "with the feature flag fully on" do
    before { Flipper.enable(:imms_api_sync_job) }

    it "syncs the vaccination" do
      perform

      expect(NHS::ImmunisationsAPI).to have_received(:sync_immunisation)
    end
  end

  context "with the feature flag off" do
    before { Flipper.disable(:imms_api_sync_job) }

    it "doesn't sync the record" do
      perform

      expect(NHS::ImmunisationsAPI).not_to have_received(:sync_immunisation)
    end
  end

  context "with the feature flag on for the correct programme" do
    before do
      Flipper.disable(:imms_api_sync_job)
      Flipper.enable(:imms_api_sync_job, programme)
    end

    it "syncs the vaccination" do
      perform

      expect(NHS::ImmunisationsAPI).to have_received(:sync_immunisation)
    end
  end

  context "with the feature flag on for the wrong programme" do
    before do
      Flipper.disable(:imms_api_sync_job)
      Flipper.enable(:imms_api_sync_job, other_programme)
    end

    let(:other_programme) { Programme.hpv }

    it "doesn't sync the vaccination" do
      perform

      expect(NHS::ImmunisationsAPI).not_to have_received(:sync_immunisation)
    end
  end

  context "with the feature flag on for MMR but off for MMRV" do
    before do
      Flipper.enable(:mmrv)

      Flipper.disable(:imms_api_sync_job)
      Flipper.enable(:imms_api_sync_job, mmr_programme)
    end

    let(:mmr_programme) do
      Programme.mmr.variant_for(
        disease_types: Programme::Variant::DISEASE_TYPES.fetch("mmr")
      )
    end

    context "with an MMR vaccination" do
      let(:programme) { mmr_programme }

      it "does sync the vaccination" do
        perform

        expect(NHS::ImmunisationsAPI).to have_received(:sync_immunisation)
      end
    end

    context "with an MMRV vaccination" do
      let(:programme) do
        Flipper.enable(:mmrv)

        Programme.mmr.variant_for(
          disease_types: Programme::Variant::DISEASE_TYPES.fetch("mmrv")
        )
      end

      it "doesn't sync the vaccination" do
        perform

        expect(NHS::ImmunisationsAPI).not_to have_received(:sync_immunisation)
      end
    end
  end
end
