# frozen_string_literal: true

describe VaccinationNotificationCriteria do
  describe "#call" do
    subject(:notify_parents) { described_class.call(vaccination_record:) }

    let(:programme) { build(:programme) }
    let(:patient) { create(:patient) }
    let(:vaccination_record) do
      build(:vaccination_record, patient:, programme:)
    end

    context "when patient has no consents" do
      it { should be_truthy }
    end

    context "when patient has consents for different programmes" do
      before do
        other_programme_type = (Programme.types.keys - [programme.type]).sample
        other_programme = create(:programme, type: other_programme_type)
        create(
          :consent,
          patient:,
          programme: other_programme,
          notify_parents_on_vaccination: false
        )
      end

      it { should be_truthy }
    end

    context "when patient has one consent for the programme" do
      context "with notify_parents_on_vaccination true" do
        before do
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: true
          )
        end

        it { should be_truthy }
      end

      context "with notify_parents_on_vaccination false" do
        before do
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: false
          )
        end

        it { should be_falsy }
      end

      context "with notify_parents_on_vaccination nil" do
        before do
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: nil
          )
        end

        it { should be_truthy }
      end
    end

    context "when patient has multiple consents for the programme" do
      context "when all consents have notify_parents_on_vaccination true" do
        before do
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: true
          )
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: true
          )
        end

        it { should be_truthy }
      end

      context "when some consents have notify_parents_on_vaccination false" do
        before do
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: true
          )
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: false
          )
        end

        it { should be_falsy }
      end

      context "when all consents have notify_parents_on_vaccination false" do
        before do
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: false
          )
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: false
          )
        end

        it { should be_falsy }
      end

      context "when some consents have notify_parents_on_vaccination nil" do
        before do
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: true
          )
          create(
            :consent,
            patient:,
            programme:,
            notify_parents_on_vaccination: nil
          )
        end

        it { should be_truthy }
      end
    end

    context "when patient has invalidated consents" do
      before do
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: false,
          invalidated_at: 1.day.ago,
          notes: "Invalidated consent"
        )
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: true
        )
      end

      it "ignores invalidated consents" do
        expect(notify_parents).to be_truthy
      end
    end

    context "when patient has withdrawn consents" do
      before do
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: false,
          withdrawn_at: 1.day.ago,
          notes: "Withdrawn consent",
          reason_for_refusal: :personal_choice
        )
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: true
        )
      end

      it "ignores withdrawn consents" do
        expect(notify_parents).to be_truthy
      end
    end

    context "when patient has both invalidated and withdrawn consents" do
      before do
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: false,
          invalidated_at: 1.day.ago,
          notes: "Invalidated consent"
        )
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: false,
          withdrawn_at: 1.day.ago,
          notes: "Withdrawn consent",
          reason_for_refusal: :personal_choice
        )
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: true
        )
      end

      it "ignores invalidated and withdrawn consents" do
        expect(notify_parents).to be_truthy
      end
    end

    context "when all valid consents are invalidated or withdrawn" do
      before do
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: false,
          invalidated_at: 1.day.ago,
          notes: "Invalidated consent"
        )
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: true,
          withdrawn_at: 1.day.ago,
          notes: "Withdrawn consent",
          reason_for_refusal: :personal_choice
        )
      end

      it "returns true when no valid consents remain" do
        expect(notify_parents).to be_truthy
      end
    end

    context "edge case: when patient has mix of valid and invalid consents" do
      before do
        # Valid consents
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: true
        )
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: true
        )

        # Invalid consents (should be ignored)
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: false,
          invalidated_at: 1.day.ago,
          notes: "Invalidated consent"
        )
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: false,
          withdrawn_at: 1.day.ago,
          notes: "Withdrawn consent",
          reason_for_refusal: :personal_choice
        )

        # Consents for other programmes (should be ignored)
        other_programme_type = (Programme.types.keys - [programme.type]).sample
        other_programme = create(:programme, type: other_programme_type)
        create(
          :consent,
          patient:,
          programme: other_programme,
          notify_parents_on_vaccination: false
        )
      end

      it "only considers valid consents for the specific programme" do
        expect(notify_parents).to be_truthy
      end
    end

    context "patient has only one valid consent with notify_parents_on_vaccination false among many invalid ones" do
      before do
        # One valid consent with notify_parents_on_vaccination false
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: false
        )

        # Many invalid consents with notify_parents_on_vaccination true (should be ignored)
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: true,
          invalidated_at: 1.day.ago,
          notes: "Invalidated consent"
        )
        create(
          :consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: true,
          withdrawn_at: 1.day.ago,
          notes: "Withdrawn consent",
          reason_for_refusal: :personal_choice
        )
      end

      it "returns false based on the single valid consent" do
        expect(notify_parents).to be_falsy
      end
    end
  end
end
