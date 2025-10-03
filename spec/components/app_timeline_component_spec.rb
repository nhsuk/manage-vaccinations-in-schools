# frozen_string_literal: true

describe AppTimelineComponent do
  subject(:rendered) { render_inline(described_class.new(items)) }

  context "when there are no items" do
    let(:items) { [] }

    it "does not render" do
      expect(rendered.to_html).to be_blank
    end
  end

  context "when items are present" do
    let(:items) do
      [
        { heading_text: "Step 1", description: "First step", active: true },
        {
          heading_text: "Step 2",
          description: "Past step",
          is_past_item: true
        },
        { heading_text: "Step 3", description: "Future step" }
      ]
    end

    it "renders a list of timeline items" do
      expect(rendered.css("ul.app-timeline li.app-timeline__item").count).to eq(
        3
      )
    end

    it "renders the heading text" do
      expect(rendered).to have_text("Step 1")
      expect(rendered).to have_text("Step 2")
      expect(rendered).to have_text("Step 3")
    end

    it "renders the description text" do
      expect(rendered).to have_text("First step")
      expect(rendered).to have_text("Past step")
      expect(rendered).to have_text("Future step")
    end

    it "renders a bold header for active items" do
      expect(rendered.css("h3.nhsuk-u-font-weight-bold")).to have_text("Step 1")
    end

    it "renders a large badge for active and past items" do
      expect(rendered.css("svg.app-timeline__badge")).to be_present
    end

    it "renders a small badge for future items" do
      expect(rendered.css("svg.app-timeline__badge--small")).to be_present
    end
  end

  context "when an item is blank" do
    let(:items) { [nil, { heading_text: "Step X", description: "Valid" }] }

    it "skips rendering blank items" do
      expect(rendered.css("li.app-timeline__item").count).to eq(1)
      expect(rendered).to have_text("Step X")
    end
  end
end
