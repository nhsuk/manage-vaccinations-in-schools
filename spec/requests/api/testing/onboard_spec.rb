# frozen_string_literal: true

describe "/api/testing/onboard" do
  before { Flipper.enable(:testing_api) }
  after { Flipper.disable(:testing_api) }

  let(:config) { YAML.safe_load(file_fixture(filename).read) }

  describe "POST" do
    subject(:request) do
      post "/api/testing/onboard",
           params: config.to_json,
           headers: {
             "Content-Type" => "application/json"
           }
    end

    context "with a valid configuration file" do
      let(:filename) { "onboarding/valid.yaml" }

      before do
        create(:programme, :hpv)
        create(:school, :secondary, :open, urn: "123456")
        create(:school, :secondary, :open, urn: "234567")
        create(:school, :secondary, :open, urn: "345678")
        create(:school, :secondary, :open, urn: "456789")
      end

      it "responds with created" do
        request
        expect(response).to have_http_status(:created)
      end

      it "creates the team" do
        request
        expect(Team.count).to eq(1)
      end

      it "creates sessions for the current and previous academic years" do
        request
        expect(Session.count).to eq(10)
        expect(Session.order(:academic_year).pluck(:academic_year).uniq).to eq(
          [AcademicYear.pending - 1, AcademicYear.pending]
        )
      end
    end

    context "with an invalid configuration file" do
      let(:filename) { "onboarding/invalid.yaml" }

      it "responds with an error" do
        request

        expect(response).to have_http_status(:unprocessable_content)

        errors = JSON.parse(response.body)

        expect(errors).to eq(
          {
            "clinics" => ["can't be blank"],
            "organisation.ods_code" => ["can't be blank"],
            "team.careplus_venue_code" => ["can't be blank"],
            "team.name" => ["can't be blank"],
            "team.phone" => ["can't be blank", "is invalid"],
            "team.privacy_notice_url" => ["can't be blank"],
            "team.privacy_policy_url" => ["can't be blank"],
            "team.type" => ["is not included in the list"],
            "team.workgroup" => ["can't be blank"],
            "programmes" => ["can't be blank"],
            "school.0.location" => ["can't be blank"],
            "school.0.status" => ["is not included in the list"],
            "school.0.subteam" => ["can't be blank"],
            "school.1.location" => ["can't be blank"],
            "school.1.status" => ["is not included in the list"],
            "school.1.subteam" => ["can't be blank"],
            "school.2.location" => ["can't be blank"],
            "school.2.status" => ["is not included in the list"],
            "subteam.email" => ["can't be blank"],
            "subteam.name" => ["can't be blank"]
          }
        )
      end
    end
  end
end
