# frozen_string_literal: true

describe NotificationParentSelector do
  subject(:notification_parent_selector) do
    described_class.new(vaccination_record:, consents:)
  end

  describe "#parents" do
    subject(:parents) { notification_parent_selector.parents }

    let(:programme) { Programme.sample }
    let(:academic_year) { AcademicYear.current }
    let(:patient) { create(:patient, programmes: [programme]) }
    let(:vaccination_record) do
      create(:vaccination_record, patient:, programme:, notify_parents: true)
    end

    let(:consents) { nil }

    let(:first_parent) { create(:parent) }
    let(:second_parent) { create(:parent) }

    let(:first_consent_response) { :given }
    let(:second_consent_response) { :given }

    before do
      create(:parent_relationship, patient:, parent: first_parent)
      create(:parent_relationship, patient:, parent: second_parent)

      create(
        :consent,
        first_consent_response,
        patient:,
        programme:,
        parent: first_parent
      )
      create(
        :consent,
        second_consent_response,
        patient:,
        programme:,
        parent: second_parent
      )
    end

    context "when both parents have given consent" do
      it { should contain_exactly(first_parent, second_parent) }
    end

    context "when the second parent refused consent" do
      let(:second_consent_response) { :refused }

      it { should_not include(second_parent) }
    end

    context "when the first parent did not provide a response" do
      let(:first_consent_response) { :not_provided }

      it { should_not include(first_parent) }

      context "when any consent is via self consent" do
        before { create(:consent, :self_consent, :given, patient:, programme:) }

        it "returns all patient parents instead of consenting parents" do
          expect(parents).to contain_exactly(first_parent, second_parent)
        end
      end
    end

    context "when the first parent is not contactable" do
      let(:first_parent) { create(:parent, :non_contactable) }

      it { should_not include(first_parent) }
    end

    context "when patient should not send notifications" do
      before do
        allow(patient).to receive(:send_notifications?).and_return(false)
      end

      it { should be_empty }
    end

    context "when vaccination record should not notify parents" do
      let(:vaccination_record) do
        create(:vaccination_record, patient:, programme:, notify_parents: false)
      end

      it { should be_empty }
    end

    context "when vaccination record does not set notify parents" do
      let(:vaccination_record) do
        create(:vaccination_record, patient:, programme:, notify_parents: nil)
      end

      it { should contain_exactly(first_parent, second_parent) }
    end

    context "when grouped consents are empty" do
      before { allow(ConsentGrouper).to receive(:call).and_return([]) }

      it { should be_empty }
    end

    context "when consents are explicitly provided and only the second parent's consent is included" do
      let(:consents) { second_parent.consents }

      it { should contain_exactly(second_parent) }
    end

    context "when consents are explicitly provided and empty" do
      let(:consents) { [] }

      it { should be_empty }
    end
  end
end
