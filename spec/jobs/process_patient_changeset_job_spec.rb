# frozen_string_literal: true

describe ProcessPatientChangesetJob do
  include ActiveJob::TestHelper

  let(:programme) { create(:programme, :hpv) }
  let(:team) { create(:team, programmes: [programme]) }
  let(:import) { create(:cohort_import, team:) }

  let(:patient_changeset) do
    create(
      :patient_changeset,
      import: import,
      status: :pending,
      data: {
        upload: {
          "child" => {
            "given_name" => "Betty",
            "family_name" => "Samson",
            "date_of_birth" => "2010-01-01",
            "address_postcode" => "SW1A 1AA"
          }
        },
        search_results:
      }
    )
  end

  let(:search_results) { [] }

  describe "#perform" do
    context "when changeset is already processed" do
      before { patient_changeset.processed! }

      it "does nothing" do
        expect { described_class.perform_now(patient_changeset) }.not_to(
          change { patient_changeset.reload.updated_at }
        )
      end

      it "does not enqueue CommitPatientChangesetsJob" do
        expect {
          described_class.perform_now(patient_changeset)
        }.not_to enqueue_sidekiq_job(CommitPatientChangesetsJob)
      end
    end

    context "when one unique NHS number found" do
      let(:search_results) do
        [
          {
            "step" => "no_fuzzy_with_history",
            "result" => "one_match",
            "nhs_number" => "9449306168",
            "created_at" => Time.current.iso8601(3)
          },
          {
            "step" => "no_fuzzy_with_wildcard_postcode",
            "result" => "one_match",
            "nhs_number" => "9449306168",
            "created_at" => Time.current.iso8601(3)
          }
        ]
      end

      it "saves the NHS number to child_attributes" do
        described_class.perform_now(patient_changeset)

        expect(patient_changeset.reload.child_attributes["nhs_number"]).to eq(
          "9449306168"
        )
      end

      it "saves the NHS number to pds_nhs_number" do
        described_class.perform_now(patient_changeset)

        expect(patient_changeset.reload.pds_nhs_number).to eq("9449306168")
      end

      it "marks changeset as processed" do
        described_class.perform_now(patient_changeset)

        expect(patient_changeset.reload).to be_processed
      end
    end

    context "when conflicting NHS numbers found" do
      let(:search_results) do
        [
          {
            "step" => "no_fuzzy_with_history",
            "result" => "one_match",
            "nhs_number" => "9449306168",
            "created_at" => Time.current.iso8601(3)
          },
          {
            "step" => "no_fuzzy_with_wildcard_postcode",
            "result" => "one_match",
            "nhs_number" => "9876543210",
            "created_at" => Time.current.iso8601(3)
          }
        ]
      end

      it "does not save any NHS number" do
        described_class.perform_now(patient_changeset)

        expect(
          patient_changeset.reload.child_attributes["nhs_number"]
        ).to be_nil
        expect(patient_changeset.pds_nhs_number).to be_nil
      end

      it "marks changeset as processed" do
        described_class.perform_now(patient_changeset)

        expect(patient_changeset.reload).to be_processed
      end
    end

    context "when no NHS numbers found" do
      let(:search_results) do
        [
          {
            "step" => "no_fuzzy_with_history",
            "result" => "no_matches",
            "nhs_number" => nil,
            "created_at" => Time.current.iso8601(3)
          },
          {
            "step" => "no_fuzzy_with_wildcard_postcode",
            "result" => "no_matches",
            "nhs_number" => nil,
            "created_at" => Time.current.iso8601(3)
          }
        ]
      end

      it "does not save any NHS number" do
        described_class.perform_now(patient_changeset)

        expect(
          patient_changeset.reload.child_attributes["nhs_number"]
        ).to be_nil
        expect(patient_changeset.pds_nhs_number).to be_nil
      end

      it "marks changeset as processed" do
        described_class.perform_now(patient_changeset)

        expect(patient_changeset.reload).to be_processed
      end
    end

    context "when all changesets are processed" do
      let(:search_results) do
        [
          {
            "step" => "no_fuzzy_with_history",
            "result" => "one_match",
            "nhs_number" => "9449306168",
            "created_at" => Time.current.iso8601(3)
          }
        ]
      end

      before do
        create(:patient_changeset, import: import, status: :processed)
        create(:patient_changeset, import: import, status: :processed)
      end

      it "enqueues CommitPatientChangesetsJob" do
        expect {
          described_class.perform_now(patient_changeset)
        }.to enqueue_sidekiq_job(CommitPatientChangesetsJob).with(
          import.to_global_id.to_s
        )
      end
    end

    context "when other changesets are still pending" do
      let(:search_results) do
        [
          {
            "step" => "no_fuzzy_with_history",
            "result" => "one_match",
            "nhs_number" => "9449306168",
            "created_at" => Time.current.iso8601(3)
          }
        ]
      end

      before do
        create(:patient_changeset, import: import, status: :pending)
        create(:patient_changeset, import: import, status: :pending)
      end

      it "does not enqueue CommitPatientChangesetsJob" do
        expect {
          described_class.perform_now(patient_changeset)
        }.not_to have_enqueued_job(CommitPatientChangesetsJob)
      end
    end

    context "when some changesets are processed and some pending" do
      let(:search_results) do
        [
          {
            "step" => "no_fuzzy_with_history",
            "result" => "one_match",
            "nhs_number" => "9449306168",
            "created_at" => Time.current.iso8601(3)
          }
        ]
      end

      before do
        create(:patient_changeset, import: import, status: :processed)
        create(:patient_changeset, import: import, status: :pending)
      end

      it "does not enqueue CommitPatientChangesetsJob" do
        expect {
          described_class.perform_now(patient_changeset)
        }.not_to have_enqueued_job(CommitPatientChangesetsJob)
      end
    end
  end
end
