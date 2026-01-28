# frozen_string_literal: true

describe AppTimelineItemComponent do
  subject { render_inline(described_class.new) }

  it { should have_css(".app-timeline__item") }
  it { should have_css(".app-timeline__badge") }
  it { should have_css(".app-timeline__badge--small") }

  context "with a heading" do
    subject do
      render_inline(described_class.new) { it.with_heading { "Test" } }
    end

    it { should have_css("h3.app-timeline__header", text: "Test") }
  end

  context "with a description" do
    subject do
      render_inline(described_class.new) { it.with_description { "Test" } }
    end

    it { should have_css("p.app-timeline__description", text: "Test") }
  end

  context "when active" do
    subject { render_inline(described_class.new(is_active: true)) }

    it { should_not have_css(".app-timeline__badge--small") }
  end

  context "when past" do
    subject { render_inline(described_class.new(is_past: true)) }

    it { should_not have_css(".app-timeline__badge--small") }
  end
end
