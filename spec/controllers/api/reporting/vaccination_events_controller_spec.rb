# frozen_string_literal: true

describe API::Reporting::VaccinationEventsController do
  it_behaves_like "a ReportingAPI controller"

  include ReportingAPIHelper

  describe "#group_clause" do
    let(:group_clause) { controller.send(:group_clause, params) }
    let(:params) { { group: groups } }
    let(:resulting_groups) { group_clause }

    context "given a :group param which is a comma-separated string of params to group by" do
      let(:groups) { "year_group, team" }

      it "adds event_timestamp_year and event_timestamp_month to the list" do
        expect(resulting_groups).to include(:event_timestamp_year)
        expect(resulting_groups).to include(:event_timestamp_month)
      end

      context "when the string already contains month" do
        let(:groups) { "year_group,team,month" }

        it "does not add event_timestamp_month again" do
          expect(resulting_groups.uniq).to eq(resulting_groups)
        end
      end

      context "when the string already contains year" do
        let(:groups) { "year_group,team,year" }

        it "does not add event_timestamp_year again" do
          expect(resulting_groups.uniq).to eq(resulting_groups)
        end
      end

      it "returns an array of the groups mapped to the corresponding attribute names" do
        expect(resulting_groups).to start_with([:patient_year_group, :team_name])
      end
    end

    context "given a :group param which contains duplicates" do
      let(:groups) { "year_group,team,team,team" }

      it "de-duplicates the output" do
        expect(resulting_groups).to eq(resulting_groups.uniq)
      end
    end

    context "given a :group param which contains empty elements" do
      let(:groups) { "year_group,,,team" }

      it "strips the empty elements from the output" do
        expect(resulting_groups).to eq(resulting_groups.compact)
      end
    end
  end

  describe "#index" do
    context "with the reporting_api feature flag enabled" do
      before do
        Flipper.enable(:reporting_api)
      end
      context "given a valid JWT" do
        before do
          request.headers["Authorization"] = "Bearer #{valid_jwt}"
        end
        context "with no content type requested" do
          it "responds with JSON" do
            get :index
            expect(response.content_type).to eq("application/json")
          end
        end

        context "when requesting JSON" do
          it "responds with JSON" do
            get :index, format: :json
            expect(response.content_type).to eq("application/json")
          end
        end

        context "when requesting CSV" do
          it "responds with CSV" do
            get :index, format: :csv
            expect(response.content_type).to eq("text/csv")
          end
        end
      end
    end
  end
end
