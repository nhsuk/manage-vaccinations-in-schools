# frozen_string_literal: true

require "rails_helper"

describe RemoveImmunisationImportCSVJob, type: :job do
  let(:immunisation_import_to_remove) do
    create(:immunisation_import, created_at: Time.zone.now - 90.days)
  end
  let(:immunisation_import_already_removed) do
    create(:immunisation_import, :csv_removed)
  end
  let(:immunisation_import_not_to_remove) { create(:immunisation_import) }

  describe "#perform" do
    subject(:perform) { described_class.new.perform }

    it "removes the imports older than 30 days" do
      expect { perform }.to change {
        immunisation_import_to_remove.reload.csv_removed?
      }.from(false).to(true)
    end

    it "doesn't change already removed imports" do
      expect { perform }.not_to change(
        immunisation_import_already_removed,
        :csv_removed_at
      )
    end

    it "doesn't remove a new import" do
      expect { perform }.not_to change(
        immunisation_import_not_to_remove,
        :csv_removed?
      ).from(false)
    end
  end
end
