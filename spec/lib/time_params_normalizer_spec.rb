# frozen_string_literal: true

describe TimeParamsNormalizer do
  describe ".call" do
    subject(:call_normalizer) { described_class.call!(params:, field_name:) }

    let(:field_name) { :performed_at_time }

    context "when hour and minute are blank but seconds is present" do
      let(:params) do
        {
          "performed_at_time(4i)" => "",
          "performed_at_time(5i)" => "",
          "performed_at_time(6i)" => "0"
        }
      end

      it "blanks the seconds field" do
        call_normalizer
        expect(params["performed_at_time(6i)"]).to eq("")
      end

      it "returns the params hash" do
        expect(call_normalizer).to eq(params)
      end
    end

    context "when hour and minute are nil but seconds is present" do
      let(:params) do
        {
          "performed_at_time(4i)" => nil,
          "performed_at_time(5i)" => nil,
          "performed_at_time(6i)" => "0"
        }
      end

      it "blanks the seconds field" do
        call_normalizer
        expect(params["performed_at_time(6i)"]).to eq("")
      end
    end

    context "when all time fields are blank" do
      let(:params) do
        {
          "performed_at_time(4i)" => "",
          "performed_at_time(5i)" => "",
          "performed_at_time(6i)" => ""
        }
      end

      it "leaves seconds blank" do
        call_normalizer
        expect(params["performed_at_time(6i)"]).to eq("")
      end
    end

    context "when hour and minute are blank and seconds is not present" do
      let(:params) do
        { "performed_at_time(4i)" => "", "performed_at_time(5i)" => "" }
      end

      it "does not add a seconds field" do
        call_normalizer
        expect(params).not_to have_key("performed_at_time(6i)")
      end
    end

    context "when hour is present but minute is blank" do
      let(:params) do
        {
          "performed_at_time(4i)" => "12",
          "performed_at_time(5i)" => "",
          "performed_at_time(6i)" => "0"
        }
      end

      it "does not modify seconds" do
        call_normalizer
        expect(params["performed_at_time(6i)"]).to eq("0")
      end
    end

    context "when minute is present but hour is blank" do
      let(:params) do
        {
          "performed_at_time(4i)" => "",
          "performed_at_time(5i)" => "30",
          "performed_at_time(6i)" => "0"
        }
      end

      it "does not modify seconds" do
        call_normalizer
        expect(params["performed_at_time(6i)"]).to eq("0")
      end
    end

    context "when hour and minute are both present" do
      let(:params) do
        {
          "performed_at_time(4i)" => "12",
          "performed_at_time(5i)" => "30",
          "performed_at_time(6i)" => "0"
        }
      end

      it "does not modify seconds" do
        call_normalizer
        expect(params["performed_at_time(6i)"]).to eq("0")
      end
    end

    context "with a different field name" do
      let(:field_name) { :another_time }

      let(:params) do
        {
          "another_time(4i)" => "",
          "another_time(5i)" => "",
          "another_time(6i)" => "0"
        }
      end

      it "normalizes the correct field" do
        call_normalizer
        expect(params["another_time(6i)"]).to eq("")
      end
    end

    context "when params contain other fields" do
      let(:params) do
        {
          "performed_at_date(1i)" => "2025",
          "performed_at_date(2i)" => "7",
          "performed_at_date(3i)" => "31",
          "performed_at_time(4i)" => "",
          "performed_at_time(5i)" => "",
          "performed_at_time(6i)" => "0",
          "notes" => "Some notes"
        }
      end

      it "only modifies the time seconds field" do
        call_normalizer
        expect(params["performed_at_date(1i)"]).to eq("2025")
        expect(params["performed_at_date(2i)"]).to eq("7")
        expect(params["performed_at_date(3i)"]).to eq("31")
        expect(params["performed_at_time(6i)"]).to eq("")
        expect(params["notes"]).to eq("Some notes")
      end
    end
  end
end
