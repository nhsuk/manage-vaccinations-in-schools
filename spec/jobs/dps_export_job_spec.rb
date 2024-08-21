# frozen_string_literal: true

require "rails_helper"

describe DPSExportJob, type: :job do
  before do
    create(:campaign, :active)
    allow(MESH).to receive(:send_file)
  end

  it "sends the DPS export to MESH" do
    dps_export_double = instance_double(DPSExport, csv: "csv")
    allow(DPSExport).to receive(:create!).and_return(dps_export_double)

    described_class.perform_now

    expect(dps_export_double).to have_received(:csv)
    expect(MESH).to have_received(:send_file).with(hash_including(data: "csv"))
  end
end
