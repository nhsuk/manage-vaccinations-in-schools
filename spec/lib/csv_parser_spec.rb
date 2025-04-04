# frozen_string_literal: true

describe CSVParser do
  subject(:table) { described_class.call(data) }

  let(:data) { "a header,Another-Header\n  a value  ,another value" }

  it "parses and converts the values" do
    expect(table.count).to eq(1)

    row = table.first
    expect(row.to_h).to eq(
      { a_header: "a value", another_header: "another value" }
    )
  end
end
