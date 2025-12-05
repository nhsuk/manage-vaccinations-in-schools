# frozen_string_literal: true

describe AppLocationCardComponent do
  subject(:rendered) { travel_to(today) { render_inline(component) } }

  let(:component) do
    described_class.new(location, patient_count: 100, next_session_date: today)
  end

  let(:today) { Date.new(2025, 7, 1) }

  context "with a generic clinic" do
    let(:location) { create(:generic_clinic, team: create(:team)) }

    it do
      expect(rendered).to have_text(
        "No known school (including home-schooled children)"
      )
    end

    it { should have_text("Children100 children") }

    it { should_not have_text("URN") }
    it { should_not have_text("Phase") }
    it { should_not have_text("Address") }
  end

  context "with a secondary school" do
    let(:location) do
      create(
        :school,
        :secondary,
        urn: "123456",
        name: "Waterloo Road",
        address_line_1: "10 Waterloo Street"
      )
    end

    it { should have_text("Waterloo Road") }
    it { should have_text("Children100 children") }
    it { should have_text("URN123456") }
    it { should have_text("PhaseSecondary") }
    it { should have_text("Address10 Waterloo Street") }
    it { should have_text("Next session1 July 2025") }
  end
end
