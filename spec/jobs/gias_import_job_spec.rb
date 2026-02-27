# frozen_string_literal: true

describe GIASImportJob do
  subject(:perform_now) { described_class.perform_now(dry_run:) }

  before do
    allow(GIAS).to receive(:download)
    allow(GIAS).to receive(:check_import)
    allow(GIAS).to receive(:import)
  end

  context "when a dry run" do
    let(:dry_run) { true }

    it "doesn't import" do
      expect(GIAS).to receive(:download)
      expect(GIAS).to receive(:check_import)
      expect(GIAS).not_to receive(:import)

      perform_now
    end
  end

  context "when not a dry run" do
    let(:dry_run) { false }

    it "does import" do
      expect(GIAS).to receive(:download)
      expect(GIAS).to receive(:check_import)
      expect(GIAS).to receive(:import)

      perform_now
    end
  end
end
