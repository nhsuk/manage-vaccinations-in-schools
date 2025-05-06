# frozen_string_literal: true

describe String do
  describe "#normalise_whitespace" do
    it "removes leading and trailing whitespace" do
      expect("  hello  ".normalise_whitespace).to eq("hello")
    end

    it "replaces multiple spaces with a single space" do
      expect("hello  world".normalise_whitespace).to eq("hello world")
    end

    it "handles tabs and newlines" do
      expect("hello\t\nworld".normalise_whitespace).to eq("hello world")
    end

    it "returns nil if string is empty after normalization" do
      expect("   ".normalise_whitespace).to be_nil
    end

    it "returns nil if string is empty" do
      expect("".normalise_whitespace).to be_nil
    end

    context "with UTF-8 encoded strings" do
      it "removes zero-width joiners (ZWJ)" do
        string_with_zwj = "1234\u200D567890"
        expect(string_with_zwj.normalise_whitespace).to eq("1234567890")
      end

      it "converts non-breaking spaces to regular spaces" do
        string_with_nbsp = "hello\u00A0world"
        expect(string_with_nbsp.normalise_whitespace).to eq("hello world")
      end

      it "handles strings with multiple Unicode characters" do
        complex_string = "  hello\u200D \u00A0 world\u200D  "
        expect(complex_string.normalise_whitespace).to eq("hello world")
      end
    end

    context "with non-UTF-8 encoded strings" do
      it "does not apply Unicode-specific transformations" do
        ascii_string = "hello world".encode(Encoding::ASCII)
        expect(ascii_string.normalise_whitespace).to eq("hello world")
      end
    end
  end
end
