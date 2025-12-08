# frozen_string_literal: true

describe AppLocationSearchFormComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(form, url:) }

  let(:form) { LocationSearchForm.new(request_session: {}, request_path: "/") }
  let(:url) { "/form" }

  it { should have_content("Find school") }
  it { should have_content("Any") }
  it { should have_content("Nursery") }
  it { should have_content("Primary") }
  it { should have_content("Secondary") }
  it { should have_content("Other") }
  it { should have_button("Update results") }
  it { should have_link("Clear filters", href: "/form?_clear=true") }
end
