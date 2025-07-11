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
  let!(:stubbed_request) do
    stub_request(
      :post,
      "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
    ).to_return(
      status: 201,
      body: "",
      headers: {
        location:
          "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/Immunization/ffff1111-eeee-2222-dddd-3333eeee4444"
      }
    )
  end

  describe "record_immunisation" do
    before { Flipper.enable(:immunisations_fhir_api_integration) }

    it "sends the correct JSON payload" do
      expected_body =
        File.read(Rails.root.join("spec/fixtures/fhir/immunisation.json")).chomp

      # stree-ignore
      stubbed_request =
        stub_request(
          :post, "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
        )
          .with { |request|
        expect(request.headers["Accept"]).to eq "application/fhir+json"
        expect(
          request.headers["Content-Type"]
        ).to eq "application/fhir+json"
        expect(request.body).to eq expected_body
        true
      }
          .to_return(status: 201,
                     body: "",
                     headers: {
                       location:
                         "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/Immunization/ffff1111-eeee-2222-dddd-3333eeee4444"
                     })

      described_class.record_immunisation(vaccination_record)

      expect(stubbed_request).to have_been_made
    end

    it "stores the id from the response" do
      described_class.record_immunisation(vaccination_record)

      expect(
        vaccination_record.nhs_immunisations_api_id
      ).to eq "ffff1111-eeee-2222-dddd-3333eeee4444"
    end

    it "stores the nhs_immunisations_api_synced_at from the response" do
      freeze_time do
        described_class.record_immunisation(vaccination_record)

        expect(
          vaccination_record.nhs_immunisations_api_synced_at
        ).to eq Time.current
      end
    end

    it "initialises the etag to 1" do
      described_class.record_immunisation(vaccination_record)

      expect(vaccination_record.nhs_immunisations_api_etag).to eq "1"
    end

    context "an error is returned by the api" do
      before do
        stub_request(
          :post,
          "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
        ).to_return(status: status, body: response, headers: {})
      end

      let(:status) { 201 }
      let(:code) { nil }
      let(:diagnostics) { nil }

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
                    code:
                  }
                ]
              },
              diagnostics:
            }
          ]
        }.to_json
      end

      context "unexpected response status" do
        let(:status) { 200 }
        let(:response) { "" }

        it "raises an error saying the response is unexpected" do
          expect {
            described_class.record_immunisation(vaccination_record)
          }.to raise_error(
            "Error recording vaccination record #{vaccination_record.id} to" \
              " Immunisations API: unexpected response status 200"
          )
        end
      end

      context "4XX error" do
        let(:status) { 404 }
        let(:diagnostics) { "Invalid patient ID" }

        it "raises an error with the diagnostic message" do
          expect {
            described_class.record_immunisation(vaccination_record)
          }.to raise_error(
            StandardError,
            "Error recording vaccination record #{vaccination_record.id} to" \
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

    context "the immunisations_fhir_api_integration feature flag is disabled" do
      before { Flipper.disable(:immunisations_fhir_api_integration) }

      it "does not make a request to the NHS API" do
        described_class.record_immunisation(vaccination_record)

        expect(stubbed_request).not_to have_been_made
      end
    end
  end
end
