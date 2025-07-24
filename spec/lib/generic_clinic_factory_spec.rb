# frozen_string_literal: true

describe GenericClinicFactory do
  describe "#call" do
    subject(:call) { described_class.call(organisation:) }

    let(:programmes) { [create(:programme, :hpv), create(:programme, :flu)] }

    context "with a new organisation" do
      let(:organisation) { create(:organisation, programmes:) }

      it "creates a generic clinic location" do
        expect { call }.to change(Location.generic_clinic, :count).by(1)

        location = Location.generic_clinic.first
        expect(location.organisation).to eq(organisation)
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

    context "with an existing organisation" do
      let(:organisation) do
        create(:organisation, :with_generic_clinic, programmes:)
      end

      it "doesn't create a generic clinic location" do
        organisation

        expect { call }.not_to change(Location.generic_clinic, :count)
      end
    end
  end
end
