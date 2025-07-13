# frozen_string_literal: true

describe SyncVaccinationRecordToNHSJob, type: :job do
  subject(:perform_now) { described_class.perform_now(vaccination_record) }

  before do
    allow(NHS::ImmunisationsAPI).to receive(:record_immunisation)
    allow(NHS::ImmunisationsAPI).to receive(:update_immunisation)
  end

  let(:nhs_immunisations_api_synced_at) { nil }
  let(:vaccination_record) do
    create(:vaccination_record, id: 123, nhs_immunisations_api_synced_at:)
  end

  it "sends the vaccination record to the NHS Immunisations API" do
    perform_now

    expect(NHS::ImmunisationsAPI).to have_received(:record_immunisation).with(
      vaccination_record
    )
  end

  context "when the vaccination record has been synced before" do
    let(:nhs_immunisations_api_synced_at) { 1.second.ago }

    it "updates the vaccination record with the NHS Immunisations API" do
      perform_now

      expect(NHS::ImmunisationsAPI).to have_received(:update_immunisation).with(
        vaccination_record
      )
    end
  end

  context "when the vaccination record is already in-sync" do
    let(:nhs_immunisations_api_synced_at) { 1.second.from_now }

    it "does not send the vaccination record to the NHS Immunisations API" do
      perform_now

      expect(NHS::ImmunisationsAPI).not_to have_received(:record_immunisation)
    end

    it "logs that the record has already been synced" do
      allow(Rails.logger).to receive(:info)

      perform_now

      expect(Rails.logger).to have_received(:info).with(
        "Vaccination record already synced: 123"
      )
    end
  end

  context "when the vaccination record has been discarded" do
    let(:vaccination_record) do
      create(:vaccination_record, :discarded, id: 123)
    end

    it "does not send the vaccination record to the NHS Immunisations API" do
      begin
        perform_now
      rescue StandardError
        nil
      end

      expect(NHS::ImmunisationsAPI).not_to have_received(:record_immunisation)
    end

    it "raises an error" do
      expect { perform_now }.to raise_error(
        "Vaccination record is discarded: #{vaccination_record.id}"
      )
    end
  end

  VaccinationRecord.defined_enums["outcome"].each_key do |outcome|
    next if outcome == "administered"

    context "when the vaccination record outcome is #{outcome}" do
      let(:vaccination_record) do
        create(:vaccination_record, id: 123, outcome:)
      end

      it "does not send the vaccination record to the NHS Immunisations API" do
        begin
          perform_now
        rescue StandardError
          nil
        end

        expect(NHS::ImmunisationsAPI).not_to have_received(:record_immunisation)
      end

      it "raises an error" do
        expect { perform_now }.to raise_error(
          "Vaccination record is not administered: #{vaccination_record.id}"
        )
      end
    end
  end
end
