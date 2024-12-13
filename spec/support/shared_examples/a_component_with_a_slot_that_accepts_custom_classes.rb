# frozen_string_literal: true

shared_examples "a component with a slot that accepts custom classes" do
  subject! do
    render_inline(described_class.send(:new, **kwargs)) do |component|
      component.send("with_#{slot}", classes: custom_class, **slot_kwargs) do
        content.call
      end
    end
  end

  let(:custom_class) { "purple-stripes" }

  specify "the rendered slot should have the custom class" do
    expect(rendered_content).to have_tag("*", with: { class: custom_class })
  end
end
