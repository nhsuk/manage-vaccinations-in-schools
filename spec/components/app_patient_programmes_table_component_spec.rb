# frozen_string_literal: true

describe AppPatientProgrammesTableComponent do
  subject(:rendered_component) { render_inline(component) }

  let(:component) { described_class.new(patient, programmes:) }
  let(:team) { create(:team, programmes:) }
  let(:session) { create(:session, team:, programmes:) }
  let(:nurse) do
    create(:user, :nurse, given_name: "Jane", family_name: "Smith")
  end

  let(:today) { Date.new(2025, 9, 1) }

  around { |example| travel_to(today) { example.run } }

  context "for seasonal programmes" do
    let(:patient) { create(:patient, session:) }
    let(:programmes) { create_list(:programme, 1, :flu) }

    it { should have_content("Vaccination programmes") }
    it { should have_content("Flu (Winter 2025)") }
    it { should_not have_content("Vaccinated") }
    it { should have_content("Selected for the Year 2025 to 2026 Flu cohort") }

    context "when vaccinated" do
      let(:patient) { create(:patient, :vaccinated, session:) }

      it { should have_css(".nhsuk-tag--green", text: "Vaccinated") }
      it { should have_content("Vaccinated on #{today.to_fs(:long)}") }
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

    context "when consent refused" do
      let(:patient) { create(:patient, :consent_refused, session:) }

      before { StatusUpdater.call(patient:) }

      it { should have_css(".nhsuk-tag--white", text: "Eligible") }
      it { should have_content("Refused on #{today.to_fs(:long)}") }
    end

    context "when triage outcome was 'Do not vaccinate'" do
      let(:patient) { create(:patient, :consent_given_triage_needed, session:) }

      before do
        create(
          :triage,
          :do_not_vaccinate,
          patient:,
          programme: programmes.first,
          performed_by: nurse,
          created_at: today
        )
        StatusUpdater.call(patient:)
      end

      it { should have_css(".nhsuk-tag--white", text: "Eligible") }

      it do
        expect(rendered_component).to have_content(
          "#{nurse.full_name} decided that #{patient.full_name} could not be vaccinated"
        )
      end
    end

    context "when no outcome yet but had contraindications" do
      let(:patient) { create(:patient, session:) }

      before do
        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          outcome: :contraindications,
          performed_at: today,
          session: session
        )
        StatusUpdater.call(patient:)
      end

      it { should have_css(".nhsuk-tag--white", text: "Eligible") }

      it do
        expect(rendered_component).to have_content(
          "Had contraindications on #{today.to_fs(:long)}"
        )
      end
    end

    context "when no outcome yet but was unwell" do
      let(:patient) { create(:patient, session:) }

      before do
        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          outcome: :not_well,
          performed_at: today,
          session: session
        )
        StatusUpdater.call(patient:)
      end

      it { should have_css(".nhsuk-tag--white", text: "Eligible") }
      it { should have_content("Unwell on #{today.to_fs(:long)}") }
    end

    context "when no outcome yet but refused vaccine" do
      let(:patient) { create(:patient, session:) }

      before do
        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          outcome: :refused,
          performed_at: today,
          session: session
        )
        StatusUpdater.call(patient:)
      end

      it { should have_css(".nhsuk-tag--white", text: "Eligible") }
      it { should have_content("Refused on #{today.to_fs(:long)}") }
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

    it do
      expect(rendered_component).to have_content(
        "Selected for the Year 2025 to 2026 HPV cohort"
      ).once
    end

    it { should have_content("Eligibility starts 1 September 2026").twice }

    context "when vaccinated with multiple doses" do
      let(:patient) { create(:patient, session:) }
      let(:first_dose_date) { Time.zone.local(2024, 9, 1) }
      let(:second_dose_date) { Time.zone.local(2025, 3, 1) }

      before do
        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          performed_at: first_dose_date,
          dose_sequence: 1,
          session: session
        )

        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          performed_at: second_dose_date,
          dose_sequence: 2,
          session: session
        )

        StatusUpdater.call(patient:)
      end

      it { should have_css(".nhsuk-tag--green", text: "Vaccinated") }

      it do
        expect(rendered_component).to have_content(
          "Vaccinated on #{first_dose_date.to_date.to_fs(:long)}"
        )
      end

      it do
        expect(rendered_component).to have_content(
          "Vaccinated on #{second_dose_date.to_date.to_fs(:long)}"
        )
      end

      it { should have_content("HPV") } # First dose doesn't show dose sequence
      it { should have_content("HPV (2nd dose)") }
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
