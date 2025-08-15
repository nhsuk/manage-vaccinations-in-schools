# frozen_string_literal: true

describe ProcessPatientChangesetsJob do
  let(:patient_changeset) { create(:patient_changeset) }
  let(:mock_patient) { instance_double(PDS::Patient, nhs_number: "1234567890") }

  let(:initial_search_args) do
    {
      family_name: patient_changeset.child_attributes["family_name"],
      given_name: patient_changeset.child_attributes["given_name"],
      date_of_birth: patient_changeset.child_attributes["date_of_birth"],
      address_postcode: patient_changeset.child_attributes["address_postcode"],
      history: true,
      fuzzy: false
    }
  end

  before { allow(PDS::Patient).to receive(:search).and_return(mock_patient) }

  def set_search_results(results_array)
    patient_changeset["pending_changes"]["search_results"] = results_array
  end

  shared_examples "a wildcard search step" do |search_type, attribute_name, wildcard_length|
    it "searches with wildcard #{attribute_name}" do
      original_value = patient_changeset.child_attributes[attribute_name.to_s]
      expected_wildcard = "#{original_value[0..wildcard_length - 1]}*"

      expect(PDS::Patient).to receive(:search).with(
        hash_including(attribute_name => expected_wildcard)
      ).and_return(mock_patient)

      described_class.perform_now(patient_changeset, search_type)
    end
  end

  shared_examples "a fuzzy search step" do |search_type, history_flag|
    it "searches with fuzzy matching and history:#{history_flag}" do
      expect(PDS::Patient).to receive(:search).with(
        hash_including(fuzzy: true, history: history_flag)
      ).and_return(mock_patient)

      described_class.perform_now(patient_changeset, search_type)
    end
  end

  describe "performing the job" do
    context "when patient already has NHS number" do
      before { patient_changeset.child_attributes["nhs_number"] = "9876543210" }

      it "finishes processing immediately" do
        expect(PDS::Patient).not_to receive(:search)
        expect(patient_changeset).to receive(:processed!)

        described_class.perform_now(patient_changeset)

        expect(patient_changeset["pending_changes"]["search_results"].length).to eq(0)
      end
    end

    context "on the first step (no_fuzzy_with_history)" do
      it "searches for a patient without fuzzy matching with history" do
        expect(PDS::Patient).to receive(:search).with(
          initial_search_args
        ).and_return(mock_patient)

        described_class.perform_now(patient_changeset)

        expect(patient_changeset["pending_changes"]["search_results"]).to include(
          hash_including(
            "step" => "no_fuzzy_with_history",
            "result" => "one_match",
            "nhs_number" => "1234567890"
          )
        )
      end

      context "when one match found" do
        it "saves NHS number and finishes processing" do
          described_class.perform_now(patient_changeset)

          expect(patient_changeset.child_attributes["nhs_number"]).to eq(
            "1234567890"
          )
          expect(patient_changeset).to be_processed
          expect(patient_changeset["pending_changes"]["search_results"].length).to eq(1)
        end
      end

      context "when no matches found" do
        let(:next_search_steps_on_no_match) do
          %i[
            no_fuzzy_with_wildcard_postcode
            no_fuzzy_with_wildcard_given_name
            no_fuzzy_with_wildcard_family_name
            fuzzy_without_history
            fuzzy_with_history
          ]
        end

        before do
          allow(patient_changeset.import).to receive(:slow?).and_return(false)
          allow(PDS::Patient).to receive(:search)
            .with(initial_search_args)
            .and_raise(NHS::PDS::PatientNotFound)
            .ordered
          allow(PDS::Patient).to receive(:search).and_raise(
            NHS::PDS::PatientNotFound
          )
          allow(described_class).to receive(:perform_now).and_call_original
        end

        it "proceeds to wildcard and fuzzy branch" do
          described_class.perform_now(patient_changeset)

          next_search_steps_on_no_match.each do |step|
            expect(described_class).to have_received(:perform_now).with(
              patient_changeset,
              step
            )
          end
        end
      end

      context "when too many matches found" do
        before do
          allow(patient_changeset.import).to receive(:slow?).and_return(false)
          allow(PDS::Patient).to receive(:search).with(
            initial_search_args
          ).and_raise(NHS::PDS::TooManyMatches)
          allow(described_class).to receive(:perform_now).and_call_original
        end

        it "proceeds to search without history" do
          described_class.perform_now(patient_changeset)

          expect(described_class).to have_received(:perform_now).with(
            patient_changeset,
            :no_fuzzy_without_history
          )
        end
      end
    end

    context "no_fuzzy_without_history step" do
      it "searches without history" do
        expect(PDS::Patient).to receive(:search).with(
          hash_including(history: false, fuzzy: false)
        ).and_return(mock_patient)

        described_class.perform_now(
          patient_changeset,
          :no_fuzzy_without_history
        )
      end

      context "when too many matches found" do
        before do
          allow(PDS::Patient).to receive(:search).and_raise(
            NHS::PDS::TooManyMatches
          )
        end

        it "gives up" do
          described_class.perform_now(
            patient_changeset,
            :no_fuzzy_without_history
          )

          expect(patient_changeset).to be_processed
          expect(patient_changeset.child_attributes["nhs_number"]).to be_blank
        end
      end
    end

    context "wildcard searches" do
      context "no_fuzzy_with_wildcard_postcode" do
        it_behaves_like "a wildcard search step",
                        :no_fuzzy_with_wildcard_postcode,
                        :address_postcode,
                        2

        it "proceeds to given name wildcard regardless of result" do
          allow(PDS::Patient).to receive(:search).and_return(mock_patient)
          allow(described_class).to receive(:perform_now).and_call_original

          described_class.perform_now(
            patient_changeset,
            :no_fuzzy_with_wildcard_postcode
          )

          step_names = patient_changeset["pending_changes"]["search_results"].map { |r| r[:step] }
          expect(step_names).to include(:no_fuzzy_with_wildcard_postcode)
        end
      end

      context "no_fuzzy_with_wildcard_given_name" do
        it_behaves_like "a wildcard search step",
                        :no_fuzzy_with_wildcard_given_name,
                        :given_name,
                        3
      end

      context "no_fuzzy_with_wildcard_family_name" do
        it_behaves_like "a wildcard search step",
                        :no_fuzzy_with_wildcard_family_name,
                        :family_name,
                        3
      end
    end

    context "fuzzy searches" do
      context "fuzzy_without_history" do
        it_behaves_like "a fuzzy search step", :fuzzy_without_history, false

        context "when too many matches found" do
          it "saves NHS number if unique across all searches" do
            set_search_results(
              [
                {
                  step: :no_fuzzy_with_history,
                  result: :one_match,
                  nhs_number: "1234567890"
                }
              ]
            )

            allow(PDS::Patient).to receive(:search).and_raise(
              NHS::PDS::TooManyMatches
            )

            described_class.perform_now(
              patient_changeset,
              :fuzzy_without_history
            )

            expect(patient_changeset.child_attributes["nhs_number"]).to eq(
              "1234567890"
            )
          end
        end
      end

      context "fuzzy_with_history" do
        it_behaves_like "a fuzzy search step", :fuzzy_with_history, true

        context "when no matches found" do
          before do
            allow(PDS::Patient).to receive(:search).and_raise(
              NHS::PDS::PatientNotFound
            )
          end

          it "gives up" do
            described_class.perform_now(patient_changeset, :fuzzy_with_history)

            expect(patient_changeset).to be_processed
            expect(patient_changeset.child_attributes["nhs_number"]).to be_blank
          end
        end
      end
    end

    context "NHS number uniqueness across searches" do
      context "when same NHS number found across multiple searches" do
        before do
          set_search_results(
            [
              {
                step: :no_fuzzy_with_history,
                result: :one_match,
                nhs_number: "1234567890"
              }
            ]
          )
          allow(PDS::Patient).to receive(:search).and_return(mock_patient)
        end

        it "saves the unique NHS number" do
          described_class.perform_now(patient_changeset, :fuzzy_without_history)

          expect(patient_changeset.child_attributes["nhs_number"]).to eq(
            "1234567890"
          )
        end
      end

      context "when different NHS numbers found across searches" do
        before do
          set_search_results(
            [
              {
                step: :no_fuzzy_with_history,
                result: :one_match,
                nhs_number: "1234567890"
              }
            ]
          )
          different_patient =
            instance_double(PDS::Patient, nhs_number: "0987654321")
          allow(PDS::Patient).to receive(:search).and_return(different_patient)
        end

        it "does not save any NHS number" do
          described_class.perform_now(patient_changeset, :fuzzy_without_history)

          expect(patient_changeset.child_attributes["nhs_number"]).to be_blank
        end
      end

      context "when no previous matches but current search has too many matches" do
        before do
          allow(PDS::Patient).to receive(:search).and_raise(
            NHS::PDS::TooManyMatches
          )
        end

        it "does not save NHS number" do
          described_class.perform_now(patient_changeset, :fuzzy_without_history)

          expect(patient_changeset.child_attributes["nhs_number"]).to be_blank
        end
      end
    end

    context "job enqueueing" do
      context "when import is slow" do
        before do
          allow(patient_changeset.import).to receive(:slow?).and_return(true)
          allow(PDS::Patient).to receive(:search).and_raise(
            NHS::PDS::PatientNotFound
          )
        end

        it "enqueues next search job" do
          expect(described_class).to receive(:perform_later).with(
            patient_changeset,
            :no_fuzzy_with_wildcard_postcode
          )

          described_class.perform_now(patient_changeset)
        end
      end

      context "when import is fast" do
        before do
          allow(patient_changeset.import).to receive(:slow?).and_return(false)
          allow(PDS::Patient).to receive(:search).and_raise(
            NHS::PDS::PatientNotFound
          )
          allow(described_class).to receive(:perform_now).and_call_original
        end

        it "performs next search immediately" do
          described_class.perform_now(patient_changeset)

          expect(described_class).to have_received(:perform_now).with(
            patient_changeset,
            :no_fuzzy_with_wildcard_postcode
          )
        end
      end
    end

    context "when all changesets are processed" do
      before do
        allow(patient_changeset.import.changesets).to receive(
          :pending
        ).and_return(instance_double(ActiveRecord::Relation, none?: true))
        allow(patient_changeset.import).to receive(:slow?).and_return(false)
        allow(PDS::Patient).to receive(:search).and_return(mock_patient)
      end

      it "triggers CommitPatientChangesetsJob" do
        expect(CommitPatientChangesetsJob).to receive(:perform_now).with(
          patient_changeset.import
        )

        described_class.perform_now(patient_changeset)
      end
    end
  end

  describe "#get_unique_nhs_number" do
    let(:job_instance) { described_class.new }

    it "returns NHS number when only one unique number exists" do
      set_search_results(
        [
          { nhs_number: "1234567890" },
          { nhs_number: "1234567890" },
          { nhs_number: nil }
        ]
      )

      result = job_instance.send(:get_unique_nhs_number, patient_changeset)

      expect(result).to eq("1234567890")
    end

    it "returns nil when multiple different NHS numbers exist" do
      set_search_results(
        [{ nhs_number: "1234567890" }, { nhs_number: "0987654321" }]
      )

      result = job_instance.send(:get_unique_nhs_number, patient_changeset)

      expect(result).to be_nil
    end

    it "returns nil when no NHS numbers found" do
      set_search_results([{ nhs_number: nil }, { nhs_number: nil }])

      result = job_instance.send(:get_unique_nhs_number, patient_changeset)

      expect(result).to be_nil
    end
  end
end
