# frozen_string_literal: true

describe VaccinationRecordsHelper do
  describe "#already_vaccinated_link_label" do
    subject do
      helper.already_vaccinated_link_label(session:, patient:, programme:)
    end

    let(:team) { create(:team, :with_generic_clinic, programmes: [programme]) }
    let(:session) { create(:session, :today, team:, programmes: [programme]) }
    let(:patient) { build(:patient, id: 123) }

    context "on the MMR programme" do
      let(:programme) { Programme.mmr }

      context "when patient has NOT had their first dose" do
        it { should eq("Record 1st dose as already given") }
      end

      context "when patient has had their first dose" do
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

        it { should eq("Record 2nd dose as already given") }
      end
    end

    context "on the flu programme" do
      let(:programme) { Programme.flu }

      it { should eq("Record as already vaccinated") }
    end
  end
end
