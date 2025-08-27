# frozen_string_literal: true

describe API::Reporting::ConsentsController do
  let(:programmes) { [create(:programme, :flu)] }
  let(:team) { create(:team, :with_generic_clinic, programmes:) }
  let!(:user) { create(:nurse, team: team) }
  let(:mock_cis2_info) {
    {
      "workgroups" => team.workgroup,
      "role_code" => CIS2Info::NURSE_ROLE,
      "organisation_code" => team.organisation.ods_code,
    }
  }
  let(:token) { ReportingAPI::OneTimeToken.find_or_generate_for!(user:, cis2_info: mock_cis2_info) }
  let(:jwt) { token.to_jwt }

  before do
    Flipper.enable(:reporting_api)
    
    # all requests in this spec are assumed to be authorized
    request.headers["Authorization"] = ["Bearer", jwt].join(" ")
  end

  describe "#index" do
    describe "the response body" do
      let(:body) { response.body }
      let(:data) { JSON.parse(response.body) }

      let(:hpv) { Programme.find_by(type: 'hpv') || create(:programme, :hpv) }
      let(:flu) { Programme.find_by(type: 'flu') || create(:programme, :flu) }

      let(:team) { create(:team, programmes: [hpv]) }
      let(:session) { create(:session, team:, programmes: [hpv], date: "2024-09-10".to_date) }
      let(:patient) { create(:patient, parents: build_list(:parent, 2)) }
      let!(:consent_notification) { create(:consent_notification, type: "request", session: session, programmes: [hpv], patient: patient, sent_at: "2024-07-10 09:00:00") }

      let(:other_session) { create(:session, team:, programmes: [flu], date: "2024-08-01".to_date) }
      let(:other_patient) { create(:patient, parents: build_list(:parent, 2)) }
      let!(:other_consent_notification) { create(:consent_notification, type: "request", session: other_session, programmes: [flu], patient: other_patient, sent_at: "2024-07-01 10:10:00") }

      let!(:consent_given) { create(:consent, :given, programme: flu, patient: patient) }
      let!(:consent_refused) { create(:consent, :refused, programme: flu, patient: patient) }
      let!(:consent_refused_hpv) { create(:consent, :refused, programme: hpv, patient: patient) }

      let(:params) { {} }

      before do
        create(:reporting_api_consent_notification_event, source: consent_notification)  # <- academic_year: 2024-2025
        create(:reporting_api_consent_notification_event, source: other_consent_notification) # <- academic_year: 2023-2024
      
        create(:reporting_api_consent_event, source: consent_given)
        create(:reporting_api_consent_event, source: consent_refused)
        create(:reporting_api_consent_event, source: consent_refused_hpv)

        get :index, params: params
      end

      it "is JSON" do
        expect { JSON.parse(body) }.not_to raise_error
      end

      it "has the expected keys" do
        expect(data.keys.sort).to eq( ['consented', 'no_response', 'offered',  'refused'] ) 
      end

      context "given no parameters" do
        describe "offered" do
          it "is the total number of patients for whom a consent notification event was recorded in the current academic year" do
            expect(data["offered"]).to eq(2)
          end
        end

        describe "consented" do
          it "is the total number of patients for whom consent was given in the current academic year" do
            expect(data["consented"]).to eq(1)
          end
        end

        describe "refused" do
          it "is the total number of patients for whom consent was refused in the current academic year" do
            expect(data["refused"]).to eq(2)
          end
        end
      end

      context "given a programme" do
        let(:params) { {programme: 'hpv'} }

        describe "offered" do
          it "is the total number of patients for whom a consent notification event was recorded in the current academic year for the given programme" do
            expect(data["offered"]).to eq(1)
          end
        end

        describe "consented" do
          it "is the total number of patients for whom consent was given in the current academic year for the given programme" do
            expect(data["consented"]).to eq(0)
          end
        end

        describe "refused" do
          it "is the total number of patients for whom consent was refused in the current academic year for the given programme" do
            expect(data["refused"]).to eq(1)
          end
        end
      end

      
    end
  end
end