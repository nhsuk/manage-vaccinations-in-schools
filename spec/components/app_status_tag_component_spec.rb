require "rails_helper"

RSpec.describe AppStatusTagComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:component) { described_class.new(status:, colour:, icon:) }

  let(:colour) { :white }
  let(:status) { :test_status }
  let(:icon) { nil }

  %i[white green red orange blue grey].each do |colour|
    context "when colour is #{colour}" do
      let(:colour) { colour }

      it { should have_css(".app-status-tag.nhsuk-tag.nhsuk-tag--#{colour}") }
    end
  end

  %i[tick cross].each do |icon|
    context "when icon is #{icon}" do
      let(:icon) { icon }

      it { should have_css(".nhsuk-icon__#{icon}") }
    end
  end

  context "when icon is nil" do
    let(:icon) { nil }

    it { should_not have_css(".nhsuk-icon") }
  end
end
