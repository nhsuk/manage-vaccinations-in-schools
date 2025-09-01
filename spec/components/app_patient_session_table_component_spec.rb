# frozen_string_literal: true

describe AppPatientSessionTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient_sessions) }

  context "without a session" do
    let(:patient_sessions) { [] }

    it { should have_content("No sessions") }
  end

  context "with a session" do
    let(:programmes) { [create(:programme, :hpv)] }

    let(:location) { create(:school, name: "Waterloo Road", programmes:) }
    let(:session) do
      create(:session, location:, programmes:, date: Date.new(2025, 1, 1))
    end

    # Can't use year_group here because we need an absolute date, not one
    # relative to the current academic year.
    let(:patient) { create(:patient, date_of_birth: Date.new(2011, 9, 1)) }

    let(:patient_sessions) do
      create_list(:patient_session, 1, patient:, session:)
    end

    it { should have_content("Location") }
    it { should have_content("Session dates") }
    it { should have_content("Programme") }

    it { should have_link("Waterloo Road") }
    it { should have_content("1 January 2025") }
    it { should have_content("HPV") }
  end
end
