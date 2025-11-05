# frozen_string_literal: true

describe VaccinationNotificationCriteria do
  describe "#call" do
    subject(:notify_parents) { described_class.call(vaccination_record:) }

    let(:programme) { CachedProgramme.sample }
    let(:patient) { create(:patient) }
    let(:vaccination_record) do
      build(
        :vaccination_record,
        patient:,
        programme:,
        session:,
        performed_at: Date.new(2025, 2, 1)
      )
    end
    let(:session) { create(:session, programmes: [programme]) }

    context "when patient has no consents" do
      it { should be_truthy }
    end

    context "when patient has consents for different programmes" do
      before do
        other_programme_type = (Programme.types.keys - [programme.type]).sample
        other_programme = CachedProgramme.send(other_programme_type)
        create(
          :consent,
          :self_consent,
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
            :self_consent,
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
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 1),
            notify_parents_on_vaccination: false
          )
        end

        it { should be_falsy }
      end

      context "with notify_parents_on_vaccination nil (not a self consent)" do
        before do
          create(
            :consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 1),
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
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 1),
            notify_parents_on_vaccination: true
          )
          create(
            :consent,
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 2),
            notify_parents_on_vaccination: true
          )
        end

        it { should be_truthy }
      end

      context "when some consents have notify_parents_on_vaccination false (latest false)" do
        before do
          create(
            :consent,
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 1),
            notify_parents_on_vaccination: true
          )
          create(
            :consent,
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 2),
            notify_parents_on_vaccination: false
          )
        end

        it { should be_falsy }
      end

      context "when some consents have notify_parents_on_vaccination false (latest true)" do
        before do
          create(
            :consent,
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 1),
            notify_parents_on_vaccination: false
          )
          create(
            :consent,
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 2),
            notify_parents_on_vaccination: true
          )
        end

        it { should be_truthy }
      end

      context "when all consents have notify_parents_on_vaccination false" do
        before do
          create(
            :consent,
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 1),
            notify_parents_on_vaccination: false
          )
          create(
            :consent,
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 2),
            notify_parents_on_vaccination: false
          )
        end

        it { should be_falsy }
      end

      context "when some consents have notify_parents_on_vaccination nil (non-self consent)" do
        before do
          create(
            :consent,
            :self_consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 1),
            notify_parents_on_vaccination: true
          )
          create(
            :consent,
            patient:,
            programme:,
            submitted_at: Date.new(2025, 1, 2),
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
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 1),
          notify_parents_on_vaccination: true
        )
        create(
          :consent,
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 2),
          notify_parents_on_vaccination: false,
          invalidated_at: 1.day.ago,
          notes: "Invalidated consent"
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
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 1),
          notify_parents_on_vaccination: true
        )
        create(
          :consent,
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 2),
          notify_parents_on_vaccination: false,
          withdrawn_at: 1.day.ago,
          notes: "Withdrawn consent",
          reason_for_refusal: :personal_choice
        )
      end

      it "includes withdrawn consents" do
        expect(notify_parents).to be_falsey
      end
    end

    context "when patient has both invalidated and withdrawn consents" do
      before do
        create(
          :consent,
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 1),
          notify_parents_on_vaccination: true
        )
        create(
          :consent,
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 2),
          notify_parents_on_vaccination: false,
          invalidated_at: 1.day.ago,
          notes: "Invalidated consent"
        )
        create(
          :consent,
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 3),
          notify_parents_on_vaccination: true,
          withdrawn_at: 1.day.ago,
          notes: "Withdrawn consent",
          reason_for_refusal: :personal_choice
        )
      end

      it "ignores invalidated but includes withdrawn consents" do
        expect(notify_parents).to be_truthy
      end
    end

    context "when all valid consents are invalidated" do
      before do
        create(
          :consent,
          :self_consent,
          patient:,
          programme:,
          notify_parents_on_vaccination: false,
          invalidated_at: 1.day.ago,
          notes: "Invalidated consent"
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
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 1),
          notify_parents_on_vaccination: true
        )
        create(
          :consent,
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 2),
          notify_parents_on_vaccination: true
        )

        # Invalid consents (should be ignored)
        create(
          :consent,
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 3),
          notify_parents_on_vaccination: false,
          invalidated_at: 2.days.ago,
          notes: "Invalidated consent"
        )
        create(
          :consent,
          :self_consent,
          patient:,
          programme:,
          submitted_at: Date.new(2025, 1, 4),
          notify_parents_on_vaccination: false,
          invalidated_at: 1.day.ago,
          notes: "Invalidated consent 2"
        )

        # Consents for other programmes (should be ignored)
        other_programme_type = (Programme.types.keys - [programme.type]).sample
        other_programme = CachedProgramme.send(other_programme_type)
        create(
          :consent,
          :self_consent,
          patient:,
          programme: other_programme,
          submitted_at: Date.new(2025, 1, 5),
          notify_parents_on_vaccination: false
        )
      end

      it "only considers valid consents for the specific programme" do
        expect(notify_parents).to be_truthy
      end
    end

    context "when vaccination record is not recorded in service" do
      let(:session) { nil }

      it { should be_nil }
    end
  end
end
