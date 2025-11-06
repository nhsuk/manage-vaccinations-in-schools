# frozen_string_literal: true

describe SyncVaccinationRecordToNHSJob, type: :job do
  subject(:perform) { described_class.new.perform(vaccination_record.id) }

  before { allow(NHS::ImmunisationsAPI).to receive(:sync_immunisation) }

  after { Flipper.disable(:imms_api_sync_job) }

  let(:programme) { CachedProgramme.flu }
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

    let(:other_programme) { CachedProgramme.hpv }

    it "doesn't sync the vaccination" do
      perform

      expect(NHS::ImmunisationsAPI).not_to have_received(:sync_immunisation)
    end
  end
end
