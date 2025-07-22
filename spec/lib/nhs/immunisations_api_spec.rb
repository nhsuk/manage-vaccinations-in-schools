# frozen_string_literal: true

describe NHS::ImmunisationsAPI do
  before { Flipper.enable(:immunisations_fhir_api_integration) }

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
  let(:nhs_immunisations_api_synced_at) { nil }
  let(:nhs_immunisations_api_etag) { nil }
  let(:nhs_immunisations_api_sync_pending_at) { nil }
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
      created_at: Time.zone.parse("2021-02-07T13:28:17.271+00:00"),
      nhs_immunisations_api_synced_at:,
      nhs_immunisations_api_etag:,
      nhs_immunisations_api_sync_pending_at:
    )
  end

  shared_examples "an immunisations_fhir_api_integration feature flag check" do
    context "the immunisations_fhir_api_integration feature flag is disabled" do
      before { Flipper.disable(:immunisations_fhir_api_integration) }

      it "does not make a request to the NHS API" do
        perform_request

        expect(request_stub).not_to have_been_made
      end
    end
  end

  shared_examples "unexpected response status" do |unexpected_status, action|
    context "unexpected response status" do
      let(:status) { unexpected_status }
      let(:response) { "" }

      it "raises an error saying the response is unexpected" do
        expect { perform_request }.to raise_error(
          Regexp.new(
            "Error #{action} vaccination record #{vaccination_record.id}" \
              " (to|from) Immunisations API: unexpected response status"
          )
        )
      end
    end
  end

  shared_examples "client error (4XX) handling" do |action|
    context "4XX error" do
      let(:status) { 404 }
      let(:diagnostics) { "Invalid patient ID" }

      it "raises an error with the diagnostic message" do
        expect { perform_request }.to raise_error(
          Regexp.new(
            "Error #{action} vaccination record #{vaccination_record.id}" \
              " (to|from) Immunisations API: Invalid patient ID"
          )
        )
      end
    end
  end

  shared_examples "generic error handling" do
    context "generic error" do
      let(:status) { 500 }

      it "raises an error with the diagnostic message" do
        expect { perform_request }.to raise_error(Faraday::Error)
      end
    end
  end

  describe "sync_immunisation" do
    subject(:perform_now) do
      described_class.sync_immunisation(vaccination_record)
    end

    before do
      allow(described_class).to receive(:next_sync_action).and_return(
        next_sync_action
      )

      allow(described_class).to receive(:record_immunisation)
      allow(described_class).to receive(:update_immunisation)
      allow(described_class).to receive(:delete_immunisation)

      perform_now
    end

    context "the next sync action is create" do
      let(:next_sync_action) { :create }

      it "calls update_immunisation" do
        expect(described_class).to have_received(:record_immunisation)
      end
    end

    context "the next sync action is update" do
      let(:next_sync_action) { :update }

      it "calls update_immunisation" do
        expect(described_class).to have_received(:update_immunisation)
      end
    end



    context "the next sync action is unknown" do
      let(:next_sync_action) { :nil }

      it "does not do any further action" do
        expect(described_class).not_to have_received(:record_immunisation)
        expect(described_class).not_to have_received(:update_immunisation)
      end
    end
  end

  describe "record_immunisation" do
    subject(:perform_request) do
      described_class.record_immunisation(vaccination_record)
    end

    let!(:request_stub) do
      stub_request(
        :post,
        "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
      ).to_return(status:, body:, headers:)
    end

    let(:status) { 201 }
    let(:body) { "" }
    let(:headers) do
      {
        location:
          "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/Immunization/ffff1111-eeee-2222-dddd-3333eeee4444"
      }
    end

    it "sends the correct JSON payload" do
      expected_body =
        File.read(
          Rails.root.join("spec/fixtures/fhir/immunisation-create.json")
        ).chomp

      request_stub.with do |request|
        expect(request.headers).to include(
          {
            "Accept" => "application/fhir+json",
            "Content-Type" => "application/fhir+json"
          }
        )
        expect(request.body).to eq expected_body
        true
      end

      perform_request

      expect(request_stub).to have_been_made
    end

    it "stores the id from the response" do
      perform_request

      expect(
        vaccination_record.nhs_immunisations_api_id
      ).to eq "ffff1111-eeee-2222-dddd-3333eeee4444"
    end

    it "sets the nhs_immunisations_api_synced_at" do
      freeze_time do
        perform_request

        expect(
          vaccination_record.nhs_immunisations_api_synced_at
        ).to eq Time.current
      end
    end

    it "initialises the etag to 1" do
      perform_request

      expect(vaccination_record.nhs_immunisations_api_etag).to eq "1"
    end

    context "an error is returned by the api" do
      let(:code) { nil }
      let(:diagnostics) { nil }
      let(:headers) { {} }
      let(:body) do
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

      include_examples "unexpected response status", 200, "recording"
      include_examples "client error (4XX) handling", "recording"
      include_examples "generic error handling"
    end

    include_examples "an immunisations_fhir_api_integration feature flag check"
  end

  describe "update immunisations" do
    subject(:perform_request) do
      described_class.update_immunisation(vaccination_record)
    end

    let(:status) { 200 }
    let(:body) { "" }
    let!(:request_stub) do
      stub_request(
        :put,
        "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization/ffff1111-eeee-2222-dddd-3333eeee4444"
      ).to_return(status:, body:)
    end

    before do
      vaccination_record.update(
        nhs_immunisations_api_id: "ffff1111-eeee-2222-dddd-3333eeee4444",
        nhs_immunisations_api_synced_at: Date.yesterday,
        nhs_immunisations_api_etag: 1
      )
    end

    it "sends the correct JSON payload" do
      expected_body =
        File.read(
          Rails.root.join("spec/fixtures/fhir/immunisation-update.json")
        ).chomp

      request_stub.with do |request|
        expect(request.headers).to include(
          {
            "Accept" => "application/fhir+json",
            "Content-Type" => "application/fhir+json",
            "E-Tag" => "1"
          }
        )
        expect(request.body).to eq expected_body
        true
      end

      perform_request

      expect(request_stub).to have_been_made
    end

    include_examples "an immunisations_fhir_api_integration feature flag check"

    it "sets the nhs_immunisations_api_synced_at" do
      freeze_time do
        perform_request

        expect(
          vaccination_record.nhs_immunisations_api_synced_at
        ).to eq Time.current
      end
    end

    it "increments the etag" do
      perform_request

      expect(vaccination_record.nhs_immunisations_api_etag).to eq "2"
    end

    context "an error is returned by the api" do
      let(:code) { nil }
      let(:diagnostics) { nil }

      let(:body) do
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

      include_examples "unexpected response status", 201, "updating"
      include_examples "client error (4XX) handling", "updating"
      include_examples "generic error handling"
    end
  end

  describe "delete immunisations" do
    subject(:perform_request) do
      described_class.delete_immunisation(vaccination_record)
    end

    let(:status) { 204 }
    let(:body) { "" }
    let!(:request_stub) do
      stub_request(
        :delete,
        "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization/ffff1111-eeee-2222-dddd-3333eeee4444"
      ).to_return(status:, body:)
    end

    before do
      vaccination_record.update(
        nhs_immunisations_api_id: "ffff1111-eeee-2222-dddd-3333eeee4444",
        nhs_immunisations_api_synced_at: Date.yesterday,
        nhs_immunisations_api_etag: 1
      )
    end

    it "sends the correct request" do
      request_stub.with do |request|
        expect(request.headers).to include(
          { "Accept" => "application/fhir+json", "E-Tag" => "1" }
        )
      end

      perform_request

      expect(request_stub).to have_been_made
    end

    include_examples "an immunisations_fhir_api_integration feature flag check"

    it "sets the nhs_immunisations_api_synced_at" do
      freeze_time do
        perform_request

        expect(
          vaccination_record.nhs_immunisations_api_synced_at
        ).to eq Time.current
      end
    end

    context "an error is returned by the api" do
      let(:code) { nil }
      let(:diagnostics) { nil }

      let(:body) do
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

      include_examples "unexpected response status", 200, "deleting"
      include_examples "client error (4XX) handling", "deleting"
      include_examples "generic error handling"
    end
  end

  describe "next_sync_action" do
    subject(:next_sync_action) do
      described_class.send(:next_sync_action, vaccination_record)
    end

    let(:nhs_immunisations_api_sync_pending_at) { 1.second.ago }

    context "the vaccination record has not been synced" do
      it { should eq :create }
    end

    context "the vaccination record has been synced before" do
      let(:nhs_immunisations_api_synced_at) { 2.seconds.ago }
      let(:nhs_immunisations_api_id) { Random.uuid }
      let(:nhs_immunisations_api_sync_pending_at) { 1.second.ago }

      it { should eq :update }
    end

    context "the sync pending is nil" do
      let(:nhs_immunisations_api_sync_pending_at) { nil }

      it "raises an error" do
        expect { next_sync_action }.to raise_error(
          "Vaccination record #{vaccination_record.id} has" \
            " nhs_immunisations_api_sync_pending_at set to nil"
        )
      end
    end

    context "the vaccination record is already in-sync" do
      let(:nhs_immunisations_api_synced_at) { 1.second.ago }
      let(:nhs_immunisations_api_sync_pending_at) { 2.seconds.ago }

      it { should be_nil }
    end

    context "the vaccination record has been discarded" do
      before { vaccination_record.discard! }

      it "raises an error" do
        expect { next_sync_action }.to raise_error(StandardError)
      end

      # include_examples "deletes the immunisation record if previously recorded"
    end

    VaccinationRecord.defined_enums["outcome"].each_key do |outcome|
      next if outcome == "administered"

      context "the vaccination record outcome is #{outcome}" do
        let(:vaccination_record) do
          create(
            :vaccination_record,
            outcome:,
            patient:,
            nhs_immunisations_api_synced_at:,
            nhs_immunisations_api_id:,
            nhs_immunisations_api_etag:,
            nhs_immunisations_api_sync_pending_at:
          )
        end

        it "raises an error" do
          expect { next_sync_action }.to raise_error(StandardError)
        end

        # include_examples "deletes the immunisation record if previously recorded"
      end
    end
  end
end
