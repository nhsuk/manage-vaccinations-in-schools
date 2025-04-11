# frozen_string_literal: true

describe FeatureFlagFactory do
  subject(:call) { described_class.call }

  context "with no feature flags" do
    it "creates missing feature flags" do
      expect { call }.to change(Flipper, :features).from([])
    end
  end

  context "with existing feature flags" do
    # These need to match features in `config/feature_flags.yml`.
    before do
      Flipper.enable(:basic_auth)
      Flipper.disable(:dev_tools)
    end

    it "doesn't enable or disable the flags" do
      expect(Flipper.enabled?(:basic_auth)).to be(true)
      expect(Flipper.enabled?(:dev_tools)).to be(false)

      call

      expect(Flipper.enabled?(:basic_auth)).to be(true)
      expect(Flipper.enabled?(:dev_tools)).to be(false)
    end
  end

  context "with unused feature flags" do
    before { Flipper.add(:unused) }

    it "removes the unused feature flags" do
      expect(Flipper.exist?(:unused)).to be(true)

      call

      expect(Flipper.exist?(:unused)).to be(false)
    end
  end
end
