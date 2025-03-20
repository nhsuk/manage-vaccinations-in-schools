# frozen_string_literal: true

describe ConsentOutcome do
  subject(:instance) { described_class.new(patients: Patient.all) }

  let(:programme) { create(:programme, :hpv) }
  let(:patient) { create(:patient, year_group: 8) }

  describe "#status" do
    subject(:status) { instance.status(patient, programme:) }

    context "with no consent" do
      it { should be(described_class::NO_RESPONSE) }
    end

    context "with an invalidated consent" do
      before { create(:consent, :invalidated, patient:, programme:) }

      it { should be(described_class::NO_RESPONSE) }
    end

    context "with a not provided consent" do
      before { create(:consent, :not_provided, patient:, programme:) }

      it { should be(described_class::NO_RESPONSE) }
    end

    context "with both an invalidated and not provided consent" do
      before do
        create(:consent, :invalidated, patient:, programme:)
        create(:consent, :not_provided, patient:, programme:)
      end

      it { should be(described_class::NO_RESPONSE) }
    end

    context "with a refused consent" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(described_class::REFUSED) }
    end

    context "with a given consent" do
      before { create(:consent, :given, patient:, programme:) }

      it { should be(described_class::GIVEN) }
    end

    context "with conflicting consent" do
      before do
        create(:consent, :given, patient:, programme:)
        create(
          :consent,
          :refused,
          patient:,
          programme:,
          parent: create(:parent)
        )
      end

      it { should be(described_class::CONFLICTS) }
    end

    context "with an invalidated refused and given consent" do
      before do
        create(:consent, :refused, :invalidated, patient:, programme:)
        create(:consent, :given, patient:, programme:)
      end

      it { should be(described_class::GIVEN) }
    end

    context "with self-consent" do
      before { create(:consent, :self_consent, :given, patient:, programme:) }

      it { should be(described_class::GIVEN) }

      context "and refused parental consent" do
        before { create(:consent, :refused, patient:, programme:) }

        it { should be(described_class::GIVEN) }
      end

      context "and conflicting parental consent" do
        before do
          create(:consent, :refused, patient:, programme:)
          create(
            :consent,
            :given,
            patient:,
            programme:,
            parent: create(:parent)
          )
        end

        it { should be(described_class::GIVEN) }
      end
    end
  end
end
