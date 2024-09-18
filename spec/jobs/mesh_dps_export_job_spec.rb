# frozen_string_literal: true

describe MESHDPSExportJob, type: :job do # rubocop:disable RSpec/SpecFilePathFormat
  before do
    allow(Flipper).to receive(:enabled?).with(:mesh_jobs).and_return(true)
    allow(MESH).to receive(:send_file).and_return(response_double)
  end

  let(:response_double) do
    instance_double(
      Faraday::Response,
      success?: true,
      body: '{"message_id": "1234"}',
      status: 202
    )
  end

  context "with a programme that has unexported vaccination records" do
    let!(:vaccination_record) { create :vaccination_record }

    it "creates a DPS export and sends it" do
      programme = vaccination_record.programme
      allow(DPSExport).to receive(:create!).with(programme:) {
        instance_double(DPSExport, csv: "csv", update!: nil, id: 1)
      }

      described_class.perform_now

      expect(MESH).to have_received(:send_file).with(
        hash_including(data: "csv", to: Settings.mesh.dps_mailbox)
      )
    end

    it "sets the status to accepted" do
      described_class.perform_now

      expect(DPSExport.last.status).to eq("accepted")
    end

    it "sets the message_id" do
      described_class.perform_now

      expect(DPSExport.last.message_id).to eq("1234")
    end
  end

  context "with a programme that has exported vaccination records" do
    let!(:vaccination_record) { create :vaccination_record }

    it "does not send anything" do
      create(
        :dps_export,
        programme: vaccination_record.programme,
        vaccination_records: [vaccination_record]
      )

      described_class.perform_now

      expect(MESH).not_to have_received(:send_file)
    end
  end

  context "with a programme that has no vaccination records" do
    before { create :programme }

    it "does not do a DPS export" do
      described_class.perform_now

      expect(MESH).not_to have_received(:send_file)
    end
  end

  context "when MESH returns a parseable error" do
    before { create :vaccination_record }

    let(:response_double) do
      instance_double(
        Faraday::Response,
        success?: false,
        body:
          JSON.generate(
            {
              "message_id" => "20240821092056779321_E37F1A",
              "internal_id" => "20240821092056761_487199b9",
              "detail" => [
                {
                  "event" => "SEND",
                  "code" => "12",
                  "msg" => "Unregistered to address"
                }
              ]
            }
          ),
        status: 417
      )
    end

    it "sets the status to failed" do
      described_class.perform_now

      expect(DPSExport.last.status).to eq("failed")
    end
  end

  context "mesh_jobs feature flag is disabled" do
    before do
      create :vaccination_record
      allow(Flipper).to receive(:enabled?).with(:mesh_jobs).and_return(false)
    end

    it "does not send a DPS export" do
      described_class.perform_now

      expect(MESH).not_to have_received(:send_file)
    end
  end
end
