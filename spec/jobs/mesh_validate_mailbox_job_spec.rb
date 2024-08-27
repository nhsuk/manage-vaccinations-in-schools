# frozen_string_literal: true

describe MESHValidateMailboxJob do
  before { allow(MESH).to receive(:validate_mailbox) }

  it "calls MESH.validate_mailbox when mesh_jobs is enabled" do
    allow(Flipper).to receive(:enabled?).with(:mesh_jobs).and_return(true)
    described_class.perform_now
    expect(MESH).to have_received(:validate_mailbox)
  end

  it "does not run when mesh_jobs is disabled" do
    allow(Flipper).to receive(:enabled?).with(:mesh_jobs).and_return(false)
    described_class.perform_now
    expect(MESH).not_to have_received(:validate_mailbox)
  end
end
