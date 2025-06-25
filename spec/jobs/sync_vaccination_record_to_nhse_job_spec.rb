# frozen_string_literal: true

describe SyncVaccinationRecordToNHSEJob, type: :job do
  subject(:perform_now) { described_class.perform_now(vaccination_record) }

  before { allow(NHS::ImmunisationsAPI).to receive(:record_immunisation) }

  let(:vaccination_record) do
    instance_double(VaccinationRecord, id: "123", nhse_synced_at: nil)
  end

  it "sends the vaccination record to the NHS Immunisations API" do
    perform_now

    expect(NHS::ImmunisationsAPI).to have_received(:record_immunisation).with(
      vaccination_record
    )
  end

  context "when the vaccination record has already been synced" do
    let(:vaccination_record) do
      instance_double(
        VaccinationRecord,
        id: "123",
        nhse_synced_at: Time.current
      )
    end

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
end
