# frozen_string_literal: true

describe API::Reporting::VaccinationEventsController do
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
end
