# frozen_string_literal: true

describe ConsentFormMatchingJob do
  subject(:perform) { described_class.new.perform(consent_form) }

  let(:session) { create(:session) }
  let(:consent_form) do
    create(
      :consent_form,
      session:,
      given_name: "John",
      family_name: "Smith",
      date_of_birth: Date.new(2010, 1, 1),
      address_postcode: "SW11 1AA"
    )
  end

  before do
    stub_request(
      :get,
      "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient"
    ).with(query: hash_including({})).to_return(
      body: file_fixture(response_file),
      headers: {
        "Content-Type" => "application/fhir+json"
      }
    )
  end

  context "with no matching patients" do
    let(:response_file) { "pds/search-patients-no-results-response.json" }

    it "doesn't create a consent" do
      expect { perform }.not_to change(Consent, :count)
    end
  end

  context "with one matching patient" do
    let(:response_file) { "pds/search-patients-no-results-response.json" }

    let!(:patient) do
      create(
        :patient,
        given_name: "John",
        family_name: "Smith",
        date_of_birth: Date.new(2010, 1, 1),
        session:,
        parents: []
      )
    end

    it "creates a consent" do
      expect { perform }.to change(Consent, :count).by(1)
    end

    it "creates a parent" do
      expect { perform }.to change(Parent, :count).by(1)
    end

    it "creates a parent relationship" do
      expect { perform }.to change(ParentRelationship, :count).by(1)

      expect(ParentRelationship.first).to have_attributes(
        patient:,
        parent: Parent.first
      )
    end

    context "when the case isn't the same" do
      let(:consent_form) do
        create(
          :consent_form,
          session:,
          given_name: "john",
          family_name: "SMITH",
          date_of_birth: Date.new(2010, 1, 1)
        )
      end

      it "still matches successfully" do
        expect { perform }.to change(Consent, :count).by(1)
      end
    end

    context "with a successful NHS number lookup" do
      let(:response_file) { "pds/search-patients-response.json" }

      let!(:patient) { create(:patient, nhs_number: "9449306168", session:) }

      it "creates a consent" do
        expect { perform }.to change(Consent, :count).by(1)
        expect(Consent.first.patient).to eq(patient)
      end
    end
  end

  context "with multiple matching patients" do
    let(:response_file) { "pds/search-patients-no-results-response.json" }

    before do
      create_list(
        :patient,
        2,
        given_name: consent_form.given_name,
        family_name: consent_form.family_name,
        date_of_birth: consent_form.date_of_birth,
        session:
      )
    end

    it "doesn't create a consent" do
      expect { perform }.not_to change(Consent, :count)
    end
  end
end
