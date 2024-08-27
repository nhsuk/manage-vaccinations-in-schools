# frozen_string_literal: true

describe ApplicationHelper do
  describe "#h1" do
    context "when called with only text" do
      it "returns an h1 tag with the text" do
        expect(helper.h1("Title")).to eq(
          '<h1 class="nhsuk-heading-l">Title</h1>'
        )
      end

      it "sets the page title" do
        helper.h1("Title")
        expect(helper.content_for(:page_title)).to eq("Title")
      end
    end

    context "when called with text and page_title option" do
      it "returns an h1 tag with the text" do
        expect(helper.h1("Title", page_title: "Custom")).to eq(
          '<h1 class="nhsuk-heading-l">Title</h1>'
        )
      end

      it "sets the page title from the option" do
        helper.h1("Title", page_title: "Custom")
        expect(helper.content_for(:page_title)).to eq("Custom")
      end
    end

    context "when called with size option" do
      it "returns an h1 tag with the correct heading class" do
        expect(helper.h1("Title", size: "xl")).to eq(
          '<h1 class="nhsuk-heading-xl">Title</h1>'
        )
      end
    end

    context "when called with a block" do
      it "raises an error if the title option is not provided" do
        expect { helper.h1 { "Title" } }.to raise_error(ArgumentError)
      end

      it "returns an h1 tag with the block content" do
        output = helper.h1(page_title: "Custom Title") { "Block Content" }
        expect(output).to eq('<h1 class="nhsuk-heading-l">Block Content</h1>')
      end

      it "sets the page title from the title option" do
        helper.h1(page_title: "Custom Title") { "Block Content" }
        expect(helper.content_for(:page_title)).to eq("Custom Title")
      end
    end

    context "when page title is already set" do
      before { helper.content_for(:page_title, "Existing Title") }

      it "does not override the existing page title" do
        helper.h1("New Title")
        expect(helper.content_for(:page_title)).to eq("Existing Title")
      end
    end
  end
end
