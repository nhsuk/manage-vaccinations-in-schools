# frozen_string_literal: true

describe ImportDuplicateForm do
  let(:programme) { CachedProgramme.sample }

  describe "#save" do
    subject do
      described_class.new(
        apply_changes: "apply",
        object: vaccination_record,
        current_team: team
      ).save
    end

    let(:team) { create(:team, programmes: [programme]) }
    let(:vaccination_record) { create(:vaccination_record, programme:, team:) }

    it_behaves_like "a method that updates team cached counts"
  end

  describe "#can_apply?" do
    subject { form.can_apply? }

    let(:form) { described_class.new(object:) }

    context "with vaccination records sourced from NHS immunisations API" do
      let(:object) do
        create(
          :vaccination_record,
          programme:,
          source: :nhs_immunisations_api,
          nhs_immunisations_api_identifier_system: "ABC",
          nhs_immunisations_api_identifier_value: "123"
        )
      end

      it { should be false }
    end

    context "with vaccination records not sourced from NHS immunisations API" do
      let(:session) { create(:session, programmes: [programme]) }
      let(:object) do
        create(:vaccination_record, programme:, source: :service, session:)
      end

      it { should be true }
    end

    context "with non-vaccination record objects" do
      let(:object) { create(:patient) }

      it { should be true }
    end
  end

  describe "validation" do
    subject { form.valid? }

    let(:form) { described_class.new(apply_changes:) }

    before do
      allow(form).to receive(:apply_changes_options).and_return(
        apply_changes_options
      )
    end

    context "when apply_changes is one of the options" do
      let(:apply_changes) { "apply" }
      let(:apply_changes_options) { %w[apply discard keep_both] }

      it { should be true }
    end

    context "when apply_changes is not one of the options" do
      let(:apply_changes) { "apply" }
      let(:apply_changes_options) { %w[discard keep_both] }

      it { should be false }
    end
  end

  describe "#apply_changes_options" do
    let(:form) { described_class.new(object:) }

    context "when object is a vaccination record" do
      let(:object) do
        create(:vaccination_record, programme:, source: :historical_upload)
      end

      before { allow(form).to receive(:can_keep_both?).and_return(false) }

      it "returns reduced options" do
        expect(form.apply_changes_options).to eq(%w[apply discard])
      end
    end

    context "when object is a patient record" do
      let(:object) { create(:patient) }

      before { allow(form).to receive(:can_keep_both?).and_return(true) }

      it "returns the standard options" do
        expect(form.apply_changes_options).to eq(%w[apply discard keep_both])
      end
    end

    context "when object is a vaccination record sourced from NHS immunisations API" do
      let(:object) do
        create(
          :vaccination_record,
          programme:,
          source: :nhs_immunisations_api,
          nhs_immunisations_api_identifier_system: "ABC",
          nhs_immunisations_api_identifier_value: "123"
        )
      end

      it "returns the standard options" do
        expect(form.apply_changes_options).to eq(%w[discard])
      end
    end
  end
end
