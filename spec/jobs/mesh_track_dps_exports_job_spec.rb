# frozen_string_literal: true

describe MESHTrackDPSExportsJob do
  before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    allow(Flipper).to receive(:enabled?).with(:mesh_jobs).and_return(true)
    allow(MESH).to receive(:track_message).and_return(
      instance_double(
        Faraday::Response,
        success?: true,
        body: "{\"status\": \"#{response_status}\"}"
      )
    )
  end

  let(:response_status) { "acknowledged" }

  let(:programme) { create :programme }
  let!(:dps_export) { create :dps_export, :accepted, programme: }

  it "only calls MESH.track_message for dps_exports that have accepted status" do
    create(:dps_export, programme:)
    create(:dps_export, :acknowledged, programme:)

    described_class.perform_now

    expect(MESH).to have_received(:track_message).with(dps_export.message_id)
  end

  it "marks the export as succssful when the response status is acknowledged" do
    described_class.perform_now

    expect(dps_export.reload.status).to eq "acknowledged"
  end

  context "when the response status is still accepted" do
    let(:response_status) { "accepted" }

    it "does not change the export's status" do
      described_class.perform_now

      expect(dps_export.reload.status).to eq "accepted"
    end
  end

  it "does not run when mesh_jobs is disabled" do
    allow(Flipper).to receive(:enabled?).with(:mesh_jobs).and_return(false)

    described_class.perform_now

    expect(MESH).not_to have_received(:track_message)
  end
end
