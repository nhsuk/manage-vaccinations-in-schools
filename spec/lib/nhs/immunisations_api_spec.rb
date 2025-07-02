# frozen_string_literal: true

describe NHS::ImmunisationsAPI do
  let(:organisation) { create(:organisation, ods_code: "A9A5A") }
  let(:patient) do
    create(
      :patient,
      id: 31_337,
      organisation:,
      address_postcode: "EC1A 1BB",
      nhs_number: "9449310475",
      given_name: "Sarah",
      family_name: "Taylor",
      date_of_birth: Date.new(2011, 9, 9)
    )
  end
  let(:programme) { create(:programme, :hpv) }
  let(:location) { create(:community_clinic, organisation:, ods_code: nil) }
  let(:vaccine) { create(:vaccine, :gardasil, programme:) }
  let(:batch) do
    create(:batch, vaccine:, expiry: "2023-03-20", name: "X8U375AL")
  end
  let(:session) do
    create(:session, organisation:, programmes: [programme], location:)
  end
  let(:user) do
    create(
      :user,
      organisation:,
      family_name: "Nightingale",
      given_name: "Florence"
    )
  end
  let(:vaccination_record) do
    create(
      :vaccination_record,
      uuid: "11112222-3333-4444-5555-666677778888",
      organisation:,
      patient:,
      programme:,
      location:,
      vaccine:,
      batch:,
      session:,
      performed_by_user: user,
      performed_at: Time.zone.parse("2021-02-07T13:28:17.271+00:00"),
      created_at: Time.zone.parse("2021-02-07T13:28:17.271+00:00")
    )
  end

  describe "record_immunisation" do
    it "sends the correct JSON payload" do
      expected_body =
        File.read(Rails.root.join("spec/fixtures/fhir/immunisation.json")).chomp

      # stree-ignore
      stubbed_request =
        stub_request(
          :post,
          "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
        )
          .with { |request|
            expect(request.headers["Accept"]).to eq "application/fhir+json"
            expect(
              request.headers["Content-Type"]
            ).to eq "application/fhir+json"
            expect(request.body).to eq expected_body
            true
          }
          .to_return(status: 200, body: "", headers: {})

      described_class.record_immunisation(vaccination_record)

      expect(stubbed_request).to have_been_made
    end

    context "an error is returned by the api" do
      context "4XX error" do
        let(:response) do
          {
            resourceType: "OperationOutcome",
            id: "bc2c3c82-4392-4314-9d6b-a7345f82d923",
            meta: {
              profile: [
                "https://simplifier.net/guide/UKCoreDevelopment2/ProfileUKCore-OperationOutcome"
              ]
            },
            issue: [
              {
                severity: "error",
                code: "invalid",
                details: {
                  coding: [
                    {
                      system: "https://fhir.nhs.uk/Codesystem/http-error-codes",
                      code: "NOT-FOUND"
                    }
                  ]
                },
                diagnostics: "Invalid patient ID"
              }
            ]
          }.to_json
        end

        before do
          stub_request(
            :post,
            "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
          ).to_return(status: 404, body: response, headers: {})
        end

        it "raises an error with the diagnostic message" do
          expect {
            described_class.record_immunisation(vaccination_record)
          }.to raise_error(
            StandardError,
            "Error syncing vaccination #{vaccination_record.id} record to" \
              " Immunisations API: Invalid patient ID"
          )
        end
      end

      context "generic error" do
        before do
          stub_request(
            :post,
            "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
          ).to_return(status: 500, body: nil, headers: {})
        end

        it "raises an error with the diagnostic message" do
          expect {
            described_class.record_immunisation(vaccination_record)
          }.to raise_error(Faraday::Error)
        end
      end
    end
  end
end
