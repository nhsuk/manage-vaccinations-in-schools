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
    let(:location) { create(:school, name: "Waterloo Road") }
    let(:sessions) do
      create_list(
        :session,
        1,
        academic_year: 2024,
        location:,
        patients: [patient]
      )
    end

    it { should have_content("Location") }
    it { should have_content("Academic year") }

    it { should have_link("Waterloo Road") }
    it { should have_content("2024/25") }
  end
end
