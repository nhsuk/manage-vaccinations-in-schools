require 'spec_helper'

RSpec.describe Reporting::TotalsController do
  let(:user) { create(:user) }
  let(:org) { user.organisations.first }

  describe "#index" do
    context "when the request has a JWT param" do
      let(:params) { {jwt: jwt} }
      
      let(:valid_payload) do
        { 
          "data": {
            "user": user.as_json,
            "cis2_info": {
                "selected_org": { "name": org.name, "code": org.ods_code },
                "selected_role": {
                    "code": "S8000:G8000:R8001",
                    "workgroups": ["schoolagedimmunisations"],
                },
            },
          },
        }
      end

      let(:invalid_payload) do
        {
          "user": {
            "id": -1
          }
        }
      end

      context "which is valid" do
        let(:jwt) { JWT.encode(valid_payload, Settings.mavis_reporting_app.secret, 'HS512') }

        it "responds with status 200" do
          get :index, params: {jwt: jwt}
          expect(response.status).to eq(200)
        end
      end


      context "which is not valid" do
        let(:jwt) { JWT.encode(invalid_payload, Settings.mavis_reporting_app.secret, 'HS512') }

        it "responds with status :unauthorized" do
          get :index, params: {jwt: jwt}
          expect(response.status).to eq(401)
        end
      end
    end
  end
end