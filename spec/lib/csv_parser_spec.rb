# frozen_string_literal: true

describe CSVParser do
  subject(:table) { described_class.call(data) }

  let(:data) { "a header,Another-Header\n  a value  ,another value" }

  it "parses and converts the values" do
    expect(table.count).to eq(1)

    row = table.first
    expect(row[:a_header].value).to eq("a value")
    expect(row[:a_header].column).to eq("A")
    expect(row[:a_header].row).to eq(2)
    expect(row[:a_header].cell).to eq("A2")
    expect(row[:a_header].header).to eq("a header")

    expect(row[:another_header].value).to eq("another value")
    expect(row[:another_header].column).to eq("B")
    expect(row[:another_header].row).to eq(2)
    expect(row[:another_header].cell).to eq("B2")
    expect(row[:another_header].header).to eq("Another-Header")
  end

  context "with un-normalised whitespace" do
    let(:data) { "  header\u200D \u00A0 \n clean \u200D \t value\u00A0 " }

    it "removes the characters" do
      row = table.first

      expect(row[:header].value).to eq("clean value")
    end
  end

  context "with input data in Windows-1252 encoding" do
    let(:data) { "header\nvalue with \x92 character".b }

    it "detects the encoding and converts to UTF-8" do
      row = table.first

      expect(row[:header].value.encoding).to eq(Encoding::UTF_8)
      expect(row[:header].value).to eq("value with ’ character")
    end
  end
end
