# frozen_string_literal: true

describe PatientImporter::SchoolMoveFactory do
  subject(:school_move) do
    described_class.new(row_data, patient, bulk_import:).resolve_school_move
  end

  let(:bulk_import) { false }
  let(:organisation) { create(:organisation) }
  let(:school) { create(:school) }
  let(:patient) { create(:patient, school:) }
  let(:row_data) do
    {
      school_move_source: "class_list_import",
      school_move_school_id: school.id,
      school_move_home_educated: false,
      school_move_organisation_id: organisation.id
    }
  end

  describe "#initialize" do
    it "extracts school-related attributes from row data" do
      factory = described_class.new(row_data, patient)

      expect(factory.school_move_home_educated).to be(false)
      expect(factory.school_move_source).to eq("class_list_import")
      expect(factory.school_move_school_id).to eq(school.id)
      expect(factory.school_move_organisation_id).to eq(organisation.id)
    end
  end

  describe "#resolve_school_move" do
    it { should_not be_nil }

    context "when bulk importing" do
      let(:bulk_import) { true }

      context "when bulk importing and patient has pending changes" do
        let(:patient) do
          create(:patient, pending_changes: { registration: "8BA" })
        end

        it { should be_nil }
      end

      context "when patient has no pending changes" do
        let(:patient) { create(:patient, pending_changes: {}) }

        it { should be_a(SchoolMove) }
      end
    end

    context "when patient is a new record" do
      let(:patient) { build(:patient, school: nil) }

      it "creates a school move with correct attributes" do
        expect(school_move.patient).to eq(patient)
        expect(school_move.school).to eq(school)
        expect(school_move.source).to eq("class_list_import")
      end

      context "when school_move_school_id is not provided" do
        let(:row_data) do
          {
            school_move_source: "class_list_import",
            school_move_school_id: nil,
            school_move_home_educated: true,
            school_move_organisation_id: organisation.id
          }
        end

        it "creates a school move with home_educated flag" do
          expect(school_move.patient).to eq(patient)
          expect(school_move.school).to be_nil
          expect(school_move.home_educated).to be(true)
          expect(school_move.organisation).to eq(organisation)
        end
      end
    end

    context "when patient's school has changed" do
      let(:old_school) { create(:school) }
      let(:patient) { create(:patient, school: old_school) }

      it "creates a school move to the new school" do
        expect(school_move.patient).to eq(patient)
        expect(school_move.school).to eq(school)
      end
    end

    context "when patient's home_educated status has changed" do
      let(:patient) { create(:patient, :home_educated) }

      it "creates a school move reflecting the change" do
        expect(school_move.patient).to eq(patient)
        expect(school_move.school).to eq(school)
        expect(school_move.home_educated).to be_nil
      end
    end

    context "when patient is not in the organisation" do
      before do
        allow(patient).to receive(:not_in_organisation?).and_return(true)
      end

      it "creates a school move" do
        expect(school_move.patient).to eq(patient)
        expect(school_move.school).to eq(school)
        expect(school_move.organisation).to be_nil
      end
    end

    context "when finding an existing school move" do
      let(:patient) { create(:patient, school: nil) }
      let!(:existing_school_move) { create(:school_move, patient:, school:) }

      it "reuses the existing school move" do
        expect(school_move).to eq(existing_school_move)
        expect(school_move.source).to eq("class_list_import")
      end
    end

    context "when finding an existing home education school move" do
      let(:patient) { create(:patient, school:) }
      let(:row_data) do
        {
          school_move_source: "class_list_import",
          school_move_school_id: nil,
          school_move_home_educated: true,
          school_move_organisation_id: organisation.id
        }
      end
      let!(:existing_school_move) do
        create(
          :school_move,
          patient:,
          school: nil,
          home_educated: true,
          organisation:
        )
      end

      it "reuses the existing school move" do
        expect(school_move).to eq(existing_school_move)
        expect(school_move.source).to eq("class_list_import")
      end
    end
  end
end
