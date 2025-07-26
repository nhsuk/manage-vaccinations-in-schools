# frozen_string_literal: true

describe AppSessionSearchFormComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(form, url:, programmes:) }

  let(:form) { SessionSearchForm.new(request_session: {}, request_path: "/") }
  let(:url) { "/form" }
  let(:programmes) { Programme.all }

  it { should have_content("Find session") }
  it { should have_button("Update results") }

  it do
    expect(rendered).to have_link("Clear filters", href: "/form?_clear=true")
  end
end
