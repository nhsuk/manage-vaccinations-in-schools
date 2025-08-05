# frozen_string_literal: true

describe SyncVaccinationRecordToNHSJob, type: :job do
  before { allow(NHS::ImmunisationsAPI).to receive(:sync_immunisation) }

  let(:vaccination_record) { create(:vaccination_record) }

  it "syncs the vaccination" do
    described_class.perform_now(vaccination_record)

    expect(NHS::ImmunisationsAPI).to have_received(:sync_immunisation)
  end
end
