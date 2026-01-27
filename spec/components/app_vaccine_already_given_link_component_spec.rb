# frozen_string_literal: true

describe AppVaccineAlreadyGivenLinkComponent do
  subject(:rendered) { render_inline(component) }

  let(:authorised) { true }
  let(:team) { create(:team, :with_generic_clinic, programmes: [programme]) }
  let(:session) { create(:session, :today, team:, programmes: [programme]) }
  let(:patient) { build(:patient, id: 123) }

  let(:component) { described_class.new(programme:, patient:, session:) }

  before do
    stub_authorization(
      allowed: authorised,
      klass: VaccinationRecordPolicy,
      methods: %i[record_already_vaccinated?]
    )
  end

  context "on the MMR programme" do
    let(:programme) { Programme.mmr }

    context "when authorised and has not had first dose" do
      it { should have_link("Record 1st dose as already given") }
    end

    context "when authorised and has had first dose already" do
      let(:patient) do
        build(
          :patient,
          :consent_no_response,
          id: 123,
          programmes: [Programme.mmr]
        )
      end

      before do
        patient.programme_status(
          programme,
          academic_year: AcademicYear.current
        ).dose_sequence =
          2
      end

      it { should have_link("Record 2nd dose as already given") }
    end

    context "when NOT authorised" do
      let(:authorised) { false }

      it { should_not have_link }
    end
  end

  context "on the flu programme" do
    let(:programme) { Programme.flu }

    context "when authorised" do
      it { should have_link("Record as already vaccinated") }
    end

    context "when NOT authorised" do
      let(:authorised) { false }

      it { should_not have_link }
    end
  end
end
