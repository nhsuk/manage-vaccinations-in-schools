# frozen_string_literal: true

describe TrimActiveRecordSessionsJob do
  describe "#perform" do
    subject(:perform) { described_class.new.perform }

    before do
      ActiveRecord::SessionStore::Session.create!(session_id: "1", data: "abc")
    end

    let!(:session2) do
      ActiveRecord::SessionStore::Session.create!(
        session_id: "2",
        data: "abc",
        updated_at: 60.days.ago
      )
    end

    it "deletes old sessions" do
      expect { perform }.to change(
        ActiveRecord::SessionStore::Session,
        :count
      ).from(2).to(1)
      expect { session2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
