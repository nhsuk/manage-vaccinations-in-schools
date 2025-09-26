# frozen_string_literal: true

describe GenericClinicFactory do
  describe "#call" do
    subject(:call) { described_class.call(team:, academic_year:) }

    let(:programmes) { [create(:programme, :hpv), create(:programme, :flu)] }
    let(:academic_year) { AcademicYear.pending }

    context "with a new team" do
      let(:team) { create(:team, programmes:) }

      it "creates a generic clinic location" do
        expect { call }.to change(Location.generic_clinic, :count).by(1)

        location = Location.generic_clinic.first
        expect(location.team).to eq(team)
        expect(location.year_groups).to contain_exactly(
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11
        )
      end
    end

    context "with an existing team" do
      let(:team) { create(:team, :with_generic_clinic, programmes:) }

      it "doesn't create a generic clinic location" do
        team

        expect { call }.not_to change(Location.generic_clinic, :count)
      end
    end
  end
end
