# frozen_string_literal: true

describe DataMigration::BackfillNotifyLogEntries do
  describe ".call" do
    let!(:mapped_entry) do
      create(
        :notify_log_entry,
        :email,
        template_id: "14e88a09-4281-4257-9574-6afeaeb42715",
        purpose: nil
      )
    end
    let!(:unknown_entry) do
      create(
        :notify_log_entry,
        :email,
        template_id: "99999999-9999-9999-9999-999999999999",
        purpose: nil
      )
    end

    it "backfills purpose from historical template ID mappings" do
      described_class.call

      expect(mapped_entry.reload.purpose).to eq("consent_request")
      expect(unknown_entry.reload.purpose).to be_nil
    end
  end
end
