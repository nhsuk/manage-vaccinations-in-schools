# frozen_string_literal: true

describe AppPatientSessionTableComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient, current_team: team) }

  let(:team) { create(:team) }

  context "without a session" do
    let(:patient) { create(:patient) }

    it { should have_content("No sessions") }
  end

  context "with a session" do
    let(:programmes) { [Programme.hpv, Programme.mmr] }

    let(:location) do
      create(:school, name: "Waterloo Road", programmes:, academic_year: 2024)
    end
    let(:session) do
      create(
        :session,
        team:,
        location:,
        programmes:,
        date: Date.new(2025, 1, 1)
      )
    end

    # Can't use year_group here because we need an absolute date, not one
    # relative to the current academic year.
    let(:patient) { create(:patient, date_of_birth: Date.new(2011, 9, 1)) }

    before { create_list(:patient_location, 1, patient:, session:) }

    it { should have_content("Location") }
    it { should have_content("Session dates") }
    it { should have_content("Programme") }

    it { should have_link("Waterloo Road") }
    it { should have_content("1 January 2025") }
    it { should have_content("HPV") }

    context "with multiple sessions" do
      let(:other_location) do
        create(
          :school,
          name: "Paddington Road",
          programmes: other_programmes,
          academic_year: 2024
        )
      end
      let(:other_session) do
        create(
          :session,
          team:,
          location: other_location,
          programmes: other_programmes,
          date: Date.new(2025, 2, 1)
        )
      end
      let(:other_programmes) { [Programme.hpv, Programme.menacwy] }

      before { create(:patient_location, patient:, session: other_session) }

      it { should have_link("Waterloo Road") }
      it { should have_link("Paddington Road") }

      context "with a programme type filter that matches only one session" do
        let(:component) do
          described_class.new(
            patient,
            current_team: team,
            programme_type: :menacwy
          )
        end

        it { should_not have_link("Waterloo Road") }
        it { should have_link("Paddington Road") }
      end
    end
  end
end
