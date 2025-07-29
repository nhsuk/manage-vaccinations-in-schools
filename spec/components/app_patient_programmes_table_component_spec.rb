# frozen_string_literal: true

describe AppPatientProgrammesTableComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient, programmes:) }
  let(:team) { create(:team, programmes:) }
  let(:session) { create(:session, team:, programmes:) }

  let(:today) { Date.new(2025, 9, 1) }

  around { |example| travel_to(today) { example.run } }

  context "for seasonal programmes" do
    let(:patient) { create(:patient, session:) }
    let(:programmes) { create_list(:programme, 1, :flu) }

    it { should have_content("Vaccination programmes") }
    it { should have_content("Flu (Winter 2025)") }
    it { should_not have_content("Vaccinated") }
    it { should have_content("Eligibility started 1 September 2025") }

    context "when vaccinated" do
      let(:patient) { create(:patient, :vaccinated, session:) }

      it { should have_content("Vaccinated") }
    end

    context "when vaccinated last year" do
      let(:patient) { create(:patient, session:) }

      before do
        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          performed_at: Time.zone.local(2024, 9, 1)
        )
        StatusUpdater.call(patient:)
      end

      it { should_not have_content("Vaccinated") }
    end
  end

  context "for non-seasonal programmes" do
    let(:patient) { create(:patient, session:, year_group: 8) }
    let(:programmes) do
      [
        create(:programme, :hpv),
        create(:programme, :menacwy),
        create(:programme, :td_ipv)
      ]
    end

    it { should have_content("Vaccination programmes") }
    it { should have_content("HPV") }
    it { should have_content("Td/IPV") }
    it { should have_content("MenACWY") }
    it { should have_content("Eligibility started 1 September 2025").once }
    it { should have_content("Eligibility starts 1 September 2026").twice }

    context "when vaccinated" do
      let(:patient) { create(:patient, :vaccinated, session:) }

      it { should have_content("Vaccinated") }
    end

    context "when vaccinated last year" do
      let(:patient) { create(:patient, session:) }

      before do
        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          performed_at: Time.zone.local(2024, 9, 1)
        )
        StatusUpdater.call(patient:)
      end

      it { should have_content("Vaccinated") }
    end
  end
end
