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
        expect(resulting_groups).to start_with(%i[patient_year_group team_name])
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
    let(:parsed_response) { JSON.parse(response.body) }
    let(:data) { parsed_response["data"] }

    context "with the reporting_api feature flag enabled" do
      before { Flipper.enable(:reporting_api) }

      context "given a valid JWT" do
        before { request.headers["Authorization"] = "Bearer #{valid_jwt}" }

        context "with no content type requested" do
          it "responds with JSON" do
            get :index
            expect(response.content_type).to eq(
              "application/json; charset=utf-8"
            )
          end
        end

        context "when requesting JSON" do
          it "responds with JSON" do
            get :index, format: :json
            expect(response.content_type).to eq(
              "application/json; charset=utf-8"
            )
          end
        end

        context "when requesting CSV" do
          it "responds with CSV" do
            get :index, format: :csv
            expect(response.content_type).to eq("text/csv")
          end
        end

        describe "groups" do
          let(:location) { create(:school) }
          let(:group) { "programme" }
          let(:vac_session) { create(:session, location: location) }
          let(:vr) { create(:vaccination_record) }
          let(:patient) { create(:patient) }

          before do
            create_list(
              :reporting_api_vaccination_event,
              2,
              source: vr,
              for_patient: patient,
              programme_type: "flu",
              event_timestamp: Time.current.beginning_of_year + 9.months
            )
            create_list(
              :reporting_api_vaccination_event,
              3,
              source: vr,
              for_patient: patient,
              programme_type: "hpv",
              event_timestamp: Time.current.beginning_of_year + 10.months
            )
            create_list(
              :reporting_api_vaccination_event,
              4,
              source: vr,
              for_patient: patient,
              programme_type: "menacwy",
              event_timestamp: Time.current.beginning_of_year + 3.months
            )
          end

          context "given a group of programme" do
            before { get :index, params: { group: group } }

            it "returns one row for each programme type" do
              expect(data.map { |row| row["programme_type"] }.sort).to eq(
                %w[flu hpv menacwy]
              )
            end

            describe "each row" do
              it "has the total_vaccinations_performed" do
                expect(
                  data.map { |row| row["total_vaccinations_performed"] }
                ).to eq([2, 3, 4])
              end

              it "has the total_patients_vaccinated" do
                expect(
                  data.map { |row| row["total_patients_vaccinated"] }
                ).to eq([1, 1, 1])
              end
            end
          end

          context "given no group, but an academic year" do
            it "returns one row for each year and month in the current academic year with a vaccination event record" do
              get :index,
                  params: {
                    group: group,
                    academic_year: Time.current.year
                  }
              expect(
                data.map { |row| row["event_timestamp_year"] }.sort
              ).to all eq(Time.current.year)
              expect(
                data.map { |row| row["event_timestamp_month"] }.sort
              ).to eq([10, 11])
            end
          end
        end
      end
    end
  end
end
