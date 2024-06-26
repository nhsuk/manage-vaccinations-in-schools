# frozen_string_literal: true

shared_context "setup" do
  let(:component_css_class_matcher) do
    component_css_class.blank? ? nil : ".#{component_css_class}"
  end
  let(:html) { Nokogiri.parse(rendered_content) }
end
