shared_examples "a component that supports custom branding" do
  let(:default_brand) { "govuk" }
  let(:custom_brand) { "globex-corp" }

  before { Govuk::Components.configure { |conf| conf.brand = custom_brand } }

  after { Govuk::Components.reset! }

  specify "should contain the custom branding" do
    render_inline(described_class.new(**kwargs))

    expect(rendered_content).to match(Regexp.new(custom_brand))
  end

  specify "should not contain any default branding" do
    render_inline(described_class.new(**kwargs))

    expect(rendered_content).not_to match(Regexp.new(default_brand))
  end
end
