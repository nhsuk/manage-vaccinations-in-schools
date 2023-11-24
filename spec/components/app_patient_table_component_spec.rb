# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppPatientTableComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:patient_sessions) { create_list(:patient_session, 2) }
  let(:component) { described_class.new(patient_sessions:) }

  it { should have_css(".nhsuk-table") }
  it { should have_css(".nhsuk-table__head") }
  it { should have_css(".nhsuk-table__head th", text: "Name") }
  it { should have_css(".nhsuk-table__head th", text: "Date of birth") }
  it { should have_css(".nhsuk-table__head .nhsuk-table__row", count: 1) }

  it { should have_css(".nhsuk-table__body") }
  it { should have_css(".nhsuk-table__body .nhsuk-table__row", count: 2) }
end
