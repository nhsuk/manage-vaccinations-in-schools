# frozen_string_literal: true

describe ImportDuplicateForm do
  let(:programme) { Programme.sample }

  describe "#save" do
    context "resolving a vaccination record" do
      subject do
        described_class.new(
          apply_changes: "apply",
          object: vaccination_record,
          current_team: team
        ).save
      end

      let(:team) { create(:team, programmes: [programme]) }
      let(:vaccination_record) do
        create(:vaccination_record, programme:, team:)
      end

      it_behaves_like "a method that updates team cached counts"
    end

    context "resolving a patient record" do
      context "when a patient import issue includes parent relationships" do
        let(:team) { create(:team, programmes: [programme]) }
        let(:session) { create(:session, team:, programmes: [programme]) }
        let(:class_import) { create(:class_import, session:) }
        let(:existing_patient) { create(:patient) }

        let(:import_parent) { create(:parent) }
        let(:existing_parent) { create(:parent) }

        let(:import_relationship) do
          create(
            :parent_relationship,
            patient: existing_patient,
            parent: import_parent,
            type: "father"
          )
        end

        let!(:existing_relationship) do
          create(
            :parent_relationship,
            patient: existing_patient,
            parent: existing_parent,
            type: "mother"
          )
        end

        let!(:changeset) do
          create(
            :patient_changeset,
            :class_import,
            :import_issue,
            import: class_import,
            patient: existing_patient
          )
        end

        before do
          existing_patient.update!(pending_changes: { "given_name" => "Twin" })
          class_import.parent_relationships << import_relationship
        end

        it "moves imported parent relationships to the new patient when keeping both" do
          form =
            described_class.new(
              apply_changes: "keep_both",
              object: existing_patient,
              current_team: team
            )

          expect(form.save).to be(true)

          new_patient = changeset.reload.patient

          expect(new_patient).not_to eq(existing_patient)
          expect(import_relationship.reload.patient).to eq(new_patient)
          expect(existing_relationship.reload.patient).to eq(existing_patient)
        end

        it "removes imported parent relationships when discarding changes" do
          form =
            described_class.new(
              apply_changes: "discard",
              object: existing_patient,
              current_team: team
            )

          expect(form.save).to be(true)

          expect { import_relationship.reload }.to raise_error(
            ActiveRecord::RecordNotFound
          )
          expect(existing_relationship.reload.patient).to eq(existing_patient)
          expect(changeset.reload.patient).to eq(existing_patient)
        end
      end
    end
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
