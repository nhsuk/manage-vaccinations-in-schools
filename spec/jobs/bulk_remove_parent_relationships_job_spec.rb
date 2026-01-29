# frozen_string_literal: true

describe BulkRemoveParentRelationshipsJob do
  subject(:perform_job) do
    described_class.new.perform(
      import.to_global_id.to_s,
      parent_relationships_to_remove.map(&:id),
      consents.map(&:id),
      user.id,
      remove_option
    )
  end

  let(:team) { create(:team) }
  let(:file) { "valid.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/class_import/#{file}") }
  let(:import) { create(:class_import, csv:, team:) }

  let(:user) { create(:user, team:) }

  let(:consents) do
    [
      create(
        :consent,
        :given,
        parent: import.parent_relationships.includes(:parent).first.parent,
        patient: import.parent_relationships.includes(:patient).first.patient
      ),
      create(
        :consent,
        :refused,
        parent: import.parent_relationships.includes(:parent).second.parent,
        patient: import.parent_relationships.includes(:patient).second.patient
      )
    ]
  end

  before do
    import.process!
    CommitImportJob.drain
  end

  describe "#perform" do
    context "remove only parents that havent consented" do
      let(:remove_option) { "unconsented_only" }
      let(:parent_relationships_to_remove) do
        import.parent_relationships - consents.map(&:parent_relationship)
      end

      it "removes only unconsented parents" do
        expect(import.parent_relationships.count).to eq(5)
        expect { perform_job }.to change {
          import.parent_relationships.count
        }.by(-3)
      end

      it "updates import status" do
        perform_job
        expect(import.reload.status).to eq("processed")
      end
    end

    context "remove all parents" do
      let(:remove_option) { "all" }
      let(:parent_relationships_to_remove) { import.parent_relationships }

      it "removes all parents" do
        expect(import.parent_relationships.count).to eq(5)
        expect { perform_job }.to change {
          import.parent_relationships.count
        }.by(-5)
      end

      it "invalidates consents" do
        perform_job
        consents.each { |consent| expect(consent.reload).to be_invalidated }
      end

      it "updates import status" do
        perform_job
        expect(import.reload.status).to eq("processed")
      end
    end
  end
end
