# frozen_string_literal: true

describe AppPatientCardComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient) }

  let(:patient) { create(:patient) }

  it { should have_content("Child record") }

  it { should have_content("Full name") }
  it { should have_content("Date of birth") }
  it { should have_content("Address") }
end
