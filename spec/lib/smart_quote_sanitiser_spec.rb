# frozen_string_literal: true

describe SmartQuoteSanitiser do
  describe ".call" do
    it "handles a mix of smart quote characters with their dumb equivalents" do
      expect(described_class.call("“it’s ‘great’”")).to eq(%("it's 'great'"))
    end

    it "leaves strings without smart quotes unchanged" do
      expect(described_class.call("plain text")).to eq("plain text")
    end

    it "returns nil when given nil" do
      expect(described_class.call(nil)).to be_nil
    end
  end
end
