# frozen_string_literal: true

describe AppPatientSessionTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient_sessions) }

  context "without a session" do
    let(:patient_sessions) { [] }

    it { should have_content("No sessions") }
  end

  context "with a session" do
    let(:location) { create(:school, name: "Waterloo Road") }
    let(:programme) { create(:programme, :hpv) }
    let(:session) do
      create(:session, academic_year: 2024, location:, programmes: [programme])
    end

    let(:patient_sessions) { create_list(:patient_session, 1, session:) }

    it { should have_content("Location") }
    it { should have_content("Programme") }
    it { should have_content("Academic year") }

    it { should have_link("Waterloo Road") }
    it { should have_content("HPV") }
    it { should have_content("2024/25") }
  end
end
