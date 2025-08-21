# frozen_string_literal: true

describe ReportingAPI::VaccinationEvent do
  describe ".with_counts_of_outcomes" do
    before do
      create_list(:reporting_api_vaccination_event, 2,  year_group: 7, outcome: "administered" )
      create_list(:reporting_api_vaccination_event, 1,  year_group: 7, outcome: "already_had" )
      create_list(:reporting_api_vaccination_event, 3,  year_group: 8, outcome: "administered" )
      create_list(:reporting_api_vaccination_event, 2,  year_group: 8, outcome: "already_had" )
      
      
    end
    context "on a grouped resultset" do
      subject(:resultset) { described_class.group(:patient_year_group) }
      let(:results) { resultset.select(:patient_year_group).with_counts_of_outcomes.to_a }

      it "adds total_vaccinated_by_sais to the resultset" do
        expect(resultset.with_counts_of_outcomes).to all( have_attribute(:total_vaccinated_by_sais) )
      end

      describe "the total_vaccinated_by_sais attribute" do
        it "equals the count of records in the current group with vaccination_record_outcome: 'administered'" do
          expect(results.find{|event| event.patient_year_group == 7 }.total_vaccinated_by_sais).to eq( 2 )
          expect(results.find{|event| event.patient_year_group == 8 }.total_vaccinated_by_sais).to eq( 3 )
        end
      end

      it "adds total_vaccinated_elsewhere to the resultset" do
        expect(resultset.with_counts_of_outcomes).to all( have_attribute(:total_vaccinated_elsewhere) )
      end

      describe "the total_vaccinated_elsewhere attribute" do
        it "equals the count of records in the current group with vaccination_record_outcome: 'already_had'" do
          expect(results.find{|event| event.patient_year_group == 7 }.total_vaccinated_elsewhere).to eq( 1 )
          expect(results.find{|event| event.patient_year_group == 8 }.total_vaccinated_elsewhere).to eq( 2 )
        end
      end
    end
  end
end