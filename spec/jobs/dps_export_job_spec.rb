# frozen_string_literal: true

require "rails_helper"

describe DPSExportJob, type: :job do
  before { allow(MESH).to receive(:send_file) }

  it "sends the DPS export to MESH" do
    allow(DPSExport).to receive(:new).and_return(
      instance_double(DPSExport, export!: "csv")
    )

    described_class.perform_now

    expect(MESH).to have_received(:send_file).with(hash_including(data: "csv"))
  end
end
