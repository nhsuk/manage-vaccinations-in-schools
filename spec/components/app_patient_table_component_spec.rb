# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppPatientTableComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:route) { :consent }
  let(:patient_sessions) { create_list(:patient_session, 2) }
  let(:component) do
    described_class.new(
      patient_sessions:,
      tab_id: "foo",
      caption: "Foo",
      route:
    )
  end

  def have_column(text)
    have_css(".nhsuk-table__head th", text:)
  end

  it { should have_css(".nhsuk-table") }
  it { should have_css(".nhsuk-table__head") }
  it { should have_column("Name") }
  it { should have_column("Date of birth") }
  it { should have_css(".nhsuk-table__head .nhsuk-table__row", count: 1) }

  it { should have_css(".nhsuk-table__body") }
  it { should have_css(".nhsuk-table__body .nhsuk-table__row", count: 2) }
  it { should have_link(patient_sessions.first.patient.full_name) }

  it "raises an ArgumentError when route is unknown" do
    expect {
      render_inline(described_class.new(patient_sessions:, route: :unknown))
    }.to raise_error(ArgumentError)
  end

  describe "when the route is :matching" do
    let(:component) do
      described_class.new(
        patient_sessions:,
        tab_id: "foo",
        route: :matching,
        consent_form: create(:consent_form),
        columns: %i[name postcode dob select_for_matching]
      )
    end

    it { should have_column("Action") }
    it { should have_column("Postcode") }
    it { should_not have_link(patient_sessions.first.patient.full_name) }
  end
end
