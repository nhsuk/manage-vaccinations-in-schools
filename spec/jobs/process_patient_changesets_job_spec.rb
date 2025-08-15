# frozen_string_literal: true

describe ProcessPatientChangesetsJob do
  describe "performing the job" do
    context "on the first step" do
      it "searches for a patient without fuzzy matching" do
        patient_changeset = create(:patient_changeset)

        expect(PDS::Patient).to receive(:search).with(
          family_name: patient_changeset.child_attributes["family_name"],
          given_name: patient_changeset.child_attributes["given_name"],
          date_of_birth: patient_changeset.child_attributes["date_of_birth"],
          address_postcode:
            patient_changeset.child_attributes["address_postcode"]
        ).and_return([:one_match, instance_double(PDS::Patient, nhs_number: "1234567890")])

        described_class.perform_now(patient_changeset)

        expect(patient_changeset.search_results).to include(
          step: :no_fuzzy_with_history,
          result: :one_match,
          nhs_number: "1234567890"
        )
      end
    end
  end
end
