# frozen_string_literal: true

describe AppImportStatusComponent, type: :component do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(import: import, break_tag: break_tag) }
  let(:import) do
    double(
      "Import",
      status: status,
      pending_import?: pending_import,
      remaining_time: "2 minutes"
    )
  end
  let(:break_tag) { false }
  let(:pending_import) { false }

  context "when status is pending_import" do
    let(:status) { "pending_import" }
    let(:pending_import) { true }

    it { should have_css(".nhsuk-tag--blue", text: "Processing") }
    it { should have_css(".nhsuk-u-secondary-text-color", text: "2 minutes") }

    context "when break_tag is true" do
      let(:break_tag) { true }

      it { should have_css("br") }
    end

    context "when break_tag is false" do
      let(:break_tag) { false }

      it { should_not have_css("br") }
    end
  end

  context "when status is rows_are_invalid" do
    let(:status) { "rows_are_invalid" }

    it { should have_css(".nhsuk-tag--red", text: "Invalid") }
    it { should_not have_content("2 minutes") }
  end

  context "when status is recorded" do
    let(:status) { "recorded" }

    it { should have_css(".nhsuk-tag--green", text: "Completed") }
    it { should_not have_content("2 minutes") }
  end
end
