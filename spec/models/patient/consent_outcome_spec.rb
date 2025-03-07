# frozen_string_literal: true

describe Patient::ConsentOutcome do
  subject(:instance) { described_class.new(patient) }

  let(:programme) { create(:programme, :hpv) }
  let(:patient) { create(:patient, year_group: 8) }

  before { patient.strict_loading!(false) }

  describe "#status" do
    subject(:status) { instance.status[programme] }

    context "with no consent" do
      it { should be(described_class::NONE) }
    end

    context "with an invalidated consent" do
      before { create(:consent, :invalidated, patient:, programme:) }

      it { should be(described_class::NONE) }
    end

    context "with a not provided consent" do
      before { create(:consent, :not_provided, patient:, programme:) }

      it { should be(described_class::NONE) }
    end

    context "with both an invalidated and not provided consent" do
      before do
        create(:consent, :invalidated, patient:, programme:)
        create(:consent, :not_provided, patient:, programme:)
      end

      it { should be(described_class::NONE) }
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

  describe "#latest" do
    subject(:latest) { instance.latest[programme] }

    context "multiple consent given responses from different parents" do
      let(:parents) { create_list(:parent, 2) }
      let(:consents) do
        [
          build(:consent, :given, parent: parents.first, programme:),
          build(:consent, :given, parent: parents.second, programme:)
        ]
      end
      let(:patient) { create(:patient, parents:, consents:) }

      it "groups consents by parent name" do
        expect(latest).to contain_exactly(consents.first, consents.second)
      end
    end

    context "multiple consent responses from same parents" do
      let(:parent) { create(:parent) }
      let(:refused_consent) { build(:consent, :refused, programme:, parent:) }
      let(:given_consent) { build(:consent, :given, programme:, parent:) }
      let(:patient) do
        create(
          :patient,
          parents: [parent],
          consents: [refused_consent, given_consent]
        )
      end

      it "returns the latest consent for each parent" do
        expect(latest).to eq [given_consent]
      end
    end

    context "with an invalidated consent" do
      let(:parent) { create(:parent) }
      let(:invalidated_consent) do
        build(:consent, :given, :invalidated, programme:, parent:)
      end
      let(:patient) do
        create(:patient, parents: [parent], consents: [invalidated_consent])
      end

      it "does not return the consent record" do
        expect(latest).not_to include(invalidated_consent)
      end
    end
  end
end
