# frozen_string_literal: true

require "rails_helper"

RSpec.describe AppPatientTableComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:route) { :consent }
  let(:patient_sessions) { create_list(:patient_session, 2) }
  let(:columns) { %i[name dob] }
  let(:filter_actions) { false }
  let(:params) do
    {
      patient_sessions:,
      tab_id: "foo",
      caption: "Foo",
      route:,
      columns:,
      filter_actions:
    }
  end
  let(:component) { described_class.new(**params) }

  def have_column(text)
    have_css(".nhsuk-table__head th", text:)
  end

  it { should have_css(".nhsuk-table") }
  it { should have_css(".nhsuk-table__head") }
  it { should have_column("Name") }
  it { should have_column("Date of birth") }
  it { should have_css(".nhsuk-table__head .nhsuk-table__row", count: 1) }

  it "includes the patient's full name" do
    expect(page).to have_text(patient_sessions.first.patient.full_name)
  end

  describe "when the patient has a common name" do
    let(:patient_sessions) do
      create_list(:patient_session, 2).tap do |ps|
        ps.first.patient.update!(common_name: "Bobby")
      end
    end

    it "includes the patient's common name" do
      expect(page).to have_text("Bobby")
    end
  end

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

  describe "filter_actions parameter" do
    context "is not set" do
      let(:component) { described_class.new(**params.except(:filter_actions)) }

      it { should_not have_text("By action needed") }
    end

    context "is enabled" do
      let(:filter_actions) { true }

      it { should have_text("By action needed") }
    end

    context "is disabled" do
      let(:filter_actions) { false }

      it { should_not have_text("By action needed") }
    end
  end
end
