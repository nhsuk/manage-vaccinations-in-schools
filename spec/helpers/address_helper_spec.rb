# frozen_string_literal: true

RSpec.describe AddressHelper do
  describe "#format_address_multi_line" do
    subject(:formatted_string) { helper.format_address_multi_line(location) }

    let(:location) do
      create(
        :location,
        :school,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA"
      )
    end

    it { should eq("10 Downing Street<br>London<br>SW1A 1AA") }
  end
end
