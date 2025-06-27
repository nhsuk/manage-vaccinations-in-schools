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
      let(:response) do
        { issue: [{ severity: "error", code:, diagnostics: }] }.to_json
      end

      before do
        stub_request(
          :post,
          "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
        ).to_return(status: 400, body: response, headers: {})

        allow(Rails.logger).to receive(:error).and_return(true)
      end

      context "generic error" do
        let(:code) { "invalid" }
        let(:diagnostics) { "Invalid patient ID" }

        it "raises an error with the correct message" do
          begin
            described_class.record_immunisation(vaccination_record)
          rescue StandardError
            nil
          end

          expect(Rails.logger).to have_received(:error).with(
            /\[invalid\] Invalid patient ID/
          )
        end
      end

      context "the error is invalid NHS number" do
        let(:code) { "exception" }
        let(:diagnostics) do
          "NHS Number: 1234567890 is invalid or it doesn't exist"
        end

        it "raises an error with the correct message" do
          begin
            described_class.record_immunisation(vaccination_record)
          rescue StandardError
            nil
          end

          expect(Rails.logger).to have_received(:error).with(
            /\[exception\] NHS Number is invalid or it doesn't exist/
          )
        end
      end
    end
  end

  describe "extract_error_info" do
    subject(:error_info) { described_class.extract_error_info(response) }

    context "response body has an error" do
      let(:response) do
        {
          issue: [
            {
              severity: "error",
              code: "invalid",
              diagnostics: "Invalid patient ID"
            }
          ]
        }.to_json
      end

      its([:code]) { should eq "invalid" }
      its([:diagnostics]) { should eq "Invalid patient ID" }
    end

    context "when the response body is empty" do
      let(:response) { nil }

      its([:code]) { should be_nil }
      its([:diagnostics]) { should eq "No response body" }
    end

    context "when the response body has no issue attribute" do
      let(:response) { "{}" }

      its([:code]) { should be_nil }
      its([:diagnostics]) { should eq "No response body" }
    end

    context "when the response body has no issues" do
      let(:response) { '{"issues": [] }' }

      its([:code]) { should be_nil }
      its([:diagnostics]) { should eq "No issues in response" }
    end

    context "the issue severity is not 'error'" do
      let(:response) do
        {
          issue: [
            {
              severity: "warning",
              code: "not-found",
              diagnostics: "Patient not found"
            }
          ]
        }.to_json
      end

      its([:code]) { should be_nil }
      its([:diagnostics]) { should eq "Issue is not an error" }
    end
  end
end
