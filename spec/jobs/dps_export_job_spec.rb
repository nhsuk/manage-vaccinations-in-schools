# frozen_string_literal: true

require "rails_helper"

describe DPSExportJob, type: :job do
  before { allow(MESH).to receive(:send_file) }

  it "generates an export with vaccination records that haven't been exported yet" do
    create :vaccination_record, exported_to_dps_at: 2.hours.ago
    vaccination2 = create :vaccination_record, exported_to_dps_at: nil

    allow(DPSExport).to receive(:new).and_return(
      instance_double(DPSExport, export_csv: "csv")
    )
    described_class.perform_now

    expect(DPSExport).to have_received(:new).with([vaccination2])
  end

  it "sets the correct body" do
    allow(DPSExport).to receive(:new).and_return(
      instance_double(DPSExport, export_csv: "csv")
    )
    described_class.perform_now

    expect(MESH).to have_received(:send_file).with(hash_including(data: "csv"))
  end
end
