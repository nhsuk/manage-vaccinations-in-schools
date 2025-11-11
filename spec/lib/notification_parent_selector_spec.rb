# frozen_string_literal: true

describe NotificationParentSelector do
  subject(:notification_parent_selector) do
    described_class.new(vaccination_record:, consents:)
  end

  describe "#parents" do
    subject(:parents) { notification_parent_selector.parents }

    let(:programme) { CachedProgramme.sample }
    let(:academic_year) { AcademicYear.current }
    let(:patient) { create(:patient, programmes: [programme]) }
    let(:vaccination_record) do
      create(
        :vaccination_record,
        patient:,
        programme:,
        notify_parents: true,
        performed_at: Time.current
      )
    end
    let(:consents) { nil }

    let(:first_parent) { create(:parent) }
    let(:second_parent) { create(:parent) }

    before do
      create(:parent_relationship, patient:, parent: first_parent)
      create(:parent_relationship, patient:, parent: second_parent)
    end

    context "when consents are provided" do
      let(:first_consent) do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          parent: first_parent,
          academic_year:
        )
      end
      let(:second_consent) do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          parent: second_parent,
          academic_year:
        )
      end
      let(:consents) { [first_consent, second_consent] }

      before do
        allow(ConsentGrouper).to receive(:call).with(
          consents,
          programme_type: programme.type,
          academic_year:
        ).and_return(consents)
      end

      context "when consents have responses" do
        it "returns contactable parents from consents with responses" do
          expect(parents).to contain_exactly(first_parent, second_parent)
        end
      end

      context "when some consents don't have responses" do
        let(:consent_without_response) do
          create(
            :consent,
            :not_provided,
            patient:,
            programme:,
            parent: first_parent,
            academic_year:
          )
        end
        let(:consents) { [consent_without_response, second_consent] }

        before do
          allow(ConsentGrouper).to receive(:call).with(
            consents,
            programme_type: programme.type,
            academic_year:
          ).and_return(consents)
          allow(consent_without_response).to receive(
            :response_provided?
          ).and_return(false)
          allow(second_consent).to receive(:response_provided?).and_return(true)
        end

        it "returns parents only from consents with provided responses" do
          expect(parents).to contain_exactly(second_parent)
        end
      end

      context "when some parents are not contactable" do
        before do
          allow(first_parent).to receive(:contactable?).and_return(false)
          allow(second_parent).to receive(:contactable?).and_return(true)
        end

        it "returns only contactable parents" do
          expect(parents).to contain_exactly(second_parent)
        end
      end

      context "when any consent is via self consent" do
        let(:self_consent) do
          create(
            :consent,
            :self_consent,
            :given,
            patient:,
            programme:,
            academic_year:
          )
        end
        let(:consents) { [first_consent, self_consent] }

        before do
          allow(ConsentGrouper).to receive(:call).with(
            consents,
            programme_type: programme.type,
            academic_year:
          ).and_return(consents)
          allow(self_consent).to receive(:via_self_consent?).and_return(true)
          allow(first_consent).to receive(:via_self_consent?).and_return(false)
        end

        it "returns all patient parents instead of consent parents" do
          expect(parents).to contain_exactly(first_parent, second_parent)
        end

        context "when some patient parents are not contactable" do
          before do
            allow(first_parent).to receive(:contactable?).and_return(false)
            allow(second_parent).to receive(:contactable?).and_return(true)
            allow(patient).to receive(:parents).and_return(
              [first_parent, second_parent]
            )
          end

          it "returns only contactable patient parents" do
            expect(parents).to contain_exactly(second_parent)
          end
        end
      end
    end

    context "when vaccination record should not notify parents" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          patient:,
          programme:,
          notify_parents: false,
          performed_at: Time.current
        )
      end
      let(:consents) { nil }

      before do
        allow(patient).to receive(:send_notifications?).and_return(true)
      end

      it "returns empty array" do
        expect(parents).to be_empty
      end
    end

    context "when patient should not send notifications" do
      let(:consents) { nil }

      before do
        allow(patient).to receive(:send_notifications?).and_return(false)
      end

      it "returns empty array" do
        expect(parents).to be_empty
      end
    end

    context "edge cases" do
      let(:consents) { [] }

      before { allow(ConsentGrouper).to receive(:call).and_return([]) }

      it "handles empty consents gracefully" do
        expect(parents).to be_empty
      end

      context "when grouped consents are empty" do
        let(:first_consent) do
          create(
            :consent,
            :given,
            patient:,
            programme:,
            parent: first_parent,
            academic_year:
          )
        end
        let(:consents) { [first_consent] }

        before do
          allow(ConsentGrouper).to receive(:call).with(
            consents,
            programme_type: programme.type,
            academic_year:
          ).and_return([])
        end

        it "returns empty array when no grouped consents" do
          expect(parents).to be_empty
        end
      end
    end

    context "when vaccination record notify_parents is false" do
      let(:vaccination_record) do
        create(:vaccination_record, patient:, programme:, notify_parents: false)
      end

      before do
        allow(patient).to receive(:send_notifications?).and_return(true)
      end

      it "returns empty array without processing consents" do
        expect(parents).to be_empty
      end
    end
  end
end
