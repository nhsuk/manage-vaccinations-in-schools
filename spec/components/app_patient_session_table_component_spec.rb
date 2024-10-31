# frozen_string_literal: true

describe AppPatientSessionTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient, sessions:) }

  let(:patient) { create(:patient) }

  context "without a session" do
    let(:sessions) { [] }

    it { should have_content("No sessions") }
  end

  context "with a session" do
    let(:location) { create(:location, :school, name: "Waterloo Road") }
    let(:sessions) { create_list(:session, 1, location:, patients: [patient]) }

    it { should have_content("Location") }
    it { should have_link("Waterloo Road") }
  end
end
