# frozen_string_literal: true

describe AppCreateNoteComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(note, open:) }

  let(:note) { Note.new(patient:, session:) }
  let(:open) { false }

  let(:patient) { create(:patient) }
  let(:session) { create(:session) }

  it { should have_css(".nhsuk-details.nhsuk-expander") }
  it { should have_css(".nhsuk-details__summary", text: "Add a note") }
end
