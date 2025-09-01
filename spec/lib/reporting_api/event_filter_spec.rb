# frozen_string_literal: true

describe ReportingAPI::EventFilter do
  subject(:event_filter) { described_class.new(params: params, filters: filters) }

  context "given params" do
    let(:params) { { thing_name: "thing_name value", some_other_param: "some_other_param_value"} }

    context "and filters (a mapping of param names to attribute names)" do
      let(:filters) { { thing_name: "attribute_name_for_thing_name", some_other_param: "attribute_name_for_some_other_param" } }

      describe "#to_where_clause" do
        it "returns a hash of attribute name (stringified) to corresponding given param value" do
          expect(event_filter.to_where_clause).to eq( {"attribute_name_for_thing_name" => "thing_name value", "attribute_name_for_some_other_param" => "some_other_param_value"} )
        end

        context "when params are given but not present in filters" do
          let(:params) { { thing_name: "thing_name value", some_other_param: "some_other_param_value", param_not_in_filters: "value of param_not_in_filters"} }

          it "does not include those params which are not present in filters" do
            expect(event_filter.to_where_clause).to eq( {"attribute_name_for_thing_name" => "thing_name value", "attribute_name_for_some_other_param" => "some_other_param_value"} )
          end
        end
      end

      describe "to_s" do
        it "returns a string with all pairs of param & value, concatenated by" do
          expect(event_filter.to_s).to eq("thing_name_thing_name_value_some_other_param_some_other_param_value")
        end

        it "replaces any number of non-ASCII-alphanumeric characters with underscores" do
          subject.params = { thing_name: "thing! \tvalue", some_other_param: "i like 小笼包"}
          expect(event_filter.to_s).to eq("thing_name_thing_value_some_other_param_i_like_")
        end
      end
    end
  end
end