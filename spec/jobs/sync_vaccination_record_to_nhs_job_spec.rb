# frozen_string_literal: true

describe SyncVaccinationRecordToNHSJob, type: :job do
  before do
    allow(NHS::ImmunisationsAPI).to receive(:sync_immunisation)
    Flipper.enable(:imms_api_sync_job)
  end

  after { Flipper.disable(:imms_api_sync_job) }

  let(:vaccination_record) { create(:vaccination_record) }

  it "syncs the vaccination" do
    described_class.perform_now(vaccination_record)

    expect(NHS::ImmunisationsAPI).to have_received(:sync_immunisation)
  end
end
