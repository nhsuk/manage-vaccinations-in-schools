# frozen_string_literal: true

describe ProcessPatientChangesetsJob do
  subject(:perform) { described_class.perform_now(patient_changeset, step) }

  let(:patient_changeset) { create(:patient_changeset, :cohort_import) }
  let(:mock_patient) { instance_double(PDS::Patient, nhs_number: "1234567890") }

  let(:step) { nil }

  before do
    allow(patient_changeset.import).to receive(:slow?).and_return(false)
  end

  context "when one match is found on initial search" do
    before { allow(PDS::Patient).to receive(:search).and_return(mock_patient) }

    it "saves NHS number and finishes processing" do
      perform

      expect(patient_changeset.child_attributes["nhs_number"]).to eq(
        "1234567890"
      )
      expect(patient_changeset).to be_processed
    end

    it "records the search result" do
      freeze_time do
        perform

        expect(patient_changeset.search_results.last).to include(
          "step" => "no_fuzzy_with_history",
          "result" => "one_match",
          "nhs_number" => "1234567890",
          "created_at" => Time.current.iso8601(3)
        )
      end
    end
  end

  context "when no match is found initially" do
    before do
      allow(PDS::Patient).to receive(:search).and_return(nil)
      allow(described_class).to receive(:perform_now).and_call_original
    end

    it "proceeds to next search steps" do
      perform

      expect(described_class).to have_received(:perform_now).with(
        patient_changeset,
        :no_fuzzy_with_wildcard_postcode
      )
    end
  end

  context "when too many matches are found initially" do
    before do
      allow(PDS::Patient).to receive(:search).and_raise(
        NHS::PDS::TooManyMatches
      )
      allow(described_class).to receive(:perform_now).and_call_original
    end

    it "falls back to no history search" do
      perform

      expect(described_class).to have_received(:perform_now).with(
        patient_changeset,
        :no_fuzzy_without_history
      )
    end
  end

  context "when a later fuzzy search finds a match" do
    let(:step) { :fuzzy }

    before do
      patient_changeset["pending_changes"]["search_results"] = [
        {
          step: :no_fuzzy_with_history,
          result: :one_match,
          nhs_number: "1234567890"
        }
      ]
      allow(PDS::Patient).to receive(:search).and_raise(
        NHS::PDS::TooManyMatches
      )
    end

    it "saves the unique NHS number" do
      perform

      expect(patient_changeset.child_attributes["nhs_number"]).to eq(
        "1234567890"
      )
    end
  end

  context "when fuzzy search returns conflicting NHS numbers" do
    let(:step) { :fuzzy }

    before do
      patient_changeset["pending_changes"]["search_results"] = [
        {
          step: :no_fuzzy_with_history,
          result: :one_match,
          nhs_number: "1234567890"
        }
      ]
      different_patient =
        instance_double(PDS::Patient, nhs_number: "1112223333")
      allow(PDS::Patient).to receive(:search).and_return(different_patient)
    end

    it "does not save any NHS number" do
      perform

      expect(patient_changeset.child_attributes["nhs_number"]).to be_blank
    end
  end

  context "when given name is too short for wildcard search" do
    let(:step) { :no_fuzzy_with_wildcard_given_name }

    before do
      patient_changeset.child_attributes["given_name"] = "Al"
      allow(described_class).to receive(:perform_now).and_call_original
      allow(PDS::Patient).to receive(:search).and_return(nil)
    end

    it "skips to the next appropriate step" do
      perform

      expect(described_class).to have_received(:perform_now).with(
        patient_changeset,
        :no_fuzzy_with_wildcard_family_name
      )

      expect(patient_changeset).to be_processed
      given_name_result =
        patient_changeset.search_results.find do |result|
          result["step"] == "no_fuzzy_with_wildcard_given_name"
        end
      expect(given_name_result["result"]).to eq("skip_step")
    end
  end

  context "when patient has no postcode" do
    before { patient_changeset.child_attributes["address_postcode"] = "" }

    it "finishes processing without performing search" do
      expect(PDS::Patient).not_to receive(:search)

      perform

      expect(patient_changeset).to be_processed
      expect(patient_changeset.search_results.last["result"]).to eq(
        "no_postcode"
      )
    end
  end

  context "when import is slow" do
    before do
      allow(patient_changeset.import).to receive(:slow?).and_return(true)
      allow(PDS::Patient).to receive(:search).and_return(nil)
    end

    it "enqueues the next search step" do
      expect(described_class).to receive(:perform_later).with(
        patient_changeset,
        :no_fuzzy_with_wildcard_postcode
      )

      perform
    end
  end

  context "when all changesets are processed" do
    before do
      allow(PDS::Patient).to receive(:search).and_return(mock_patient)
      patient_changeset.import.changesets.update_all(status: :processed)
    end

    it "triggers CommitPatientChangesetsJob" do
      expect(CommitPatientChangesetsJob).to receive(:perform_now).with(
        patient_changeset.import
      )

      perform
    end
  end

  context "rate limiting from PDS" do
    before do
      allow(PDS::Patient).to receive(:search).and_raise(
        Faraday::TooManyRequestsError
      )
    end

    it "re-raises the error" do
      expect { perform }.to raise_error(Faraday::TooManyRequestsError)
    end
  end
end
