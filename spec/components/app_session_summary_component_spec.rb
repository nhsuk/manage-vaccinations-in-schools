# frozen_string_literal: true

describe AppSessionSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(session) }

  let(:programme) { create(:programme, :hpv) }
  let(:session) { create(:session, date: Date.new(2024, 1, 1), programme:) }

  it { should have_content("Programmes") }
  it { should have_content("HPV") }

  it { should have_content("Session dates") }
  it { should have_content("1 January 2024") }

  it { should have_content("Consent period") }
  it { should have_content("Closed 1 January") }

  it { should have_content("Children") }
  it { should have_content("No children") }
end
