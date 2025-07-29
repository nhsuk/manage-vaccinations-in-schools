# frozen_string_literal: true

# == Schema Information
#
# Table name: class_imports
#
#  id                           :bigint           not null, primary key
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  processed_at                 :datetime
#  rows_count                   :integer
#  serialized_errors            :jsonb
#  status                       :integer          default("pending_import"), not null
#  year_groups                  :integer          default([]), not null, is an Array
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  location_id                  :bigint           not null
#  organisation_id              :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_class_imports_on_location_id          (location_id)
#  index_class_imports_on_organisation_id      (organisation_id)
#  index_class_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
describe ClassImport do
  subject(:class_import) do
    create(:class_import, csv:, session:, organisation:)
  end

  let(:programmes) { [create(:programme, :hpv)] }
  let(:organisation) do
    create(:organisation, :with_generic_clinic, programmes:)
  end
  let(:location) { create(:school, organisation:) }
  let(:session) { create(:session, location:, programmes:, organisation:) }

  let(:file) { "valid.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/class_import/#{file}") }

  it_behaves_like "a CSVImportable model"

  describe "#load_data!" do
    subject(:load_data!) { class_import.load_data! }

    before { load_data! }

    describe "with malformed CSV" do
      let(:file) { "malformed.csv" }

      it "is invalid" do
        expect(class_import).to be_invalid
        expect(class_import.errors[:csv]).to include(/correct format/)
      end
    end
  end

  describe "#parse_rows!" do
    subject(:parse_rows!) { class_import.parse_rows! }

    before { parse_rows! }

    describe "with a BOM" do
      let(:file) { "valid_with_bom.csv" }

      it "removes the BOM" do
        expect(class_import).to be_valid
        expect(class_import.rows.first.to_patient[:given_name]).to eq("Lena")
      end
    end

    describe "with invalid fields" do
      let(:file) { "invalid_fields.csv" }

      it "populates rows" do
        expect(class_import).to be_invalid
        expect(class_import.rows).not_to be_empty
      end
    end

    describe "with unrecognised fields" do
      let(:file) { "valid_extra_fields.csv" }

      it "populates rows" do
        expect(class_import).to be_valid
      end
    end

    describe "with valid fields" do
      let(:file) { "valid.csv" }

      it "is valid" do
        expect(class_import).to be_valid
      end

      it "accepts NHS numbers with spaces, removes spaces" do
        expect(class_import).to be_valid
        expect(class_import.rows.second.to_patient[:nhs_number]).to eq(
          "9990000026"
        )
      end

      it "parses dates in the ISO8601 format" do
        expect(class_import).to be_valid
        expect(class_import.rows.first.to_patient[:date_of_birth]).to eq(
          Date.new(2010, 1, 1)
        )
      end

      it "parses dates in the DD/MM/YYYY format" do
        expect(class_import).to be_valid
        expect(class_import.rows.second.to_patient[:date_of_birth]).to eq(
          Date.new(2010, 1, 2)
        )
      end
    end

    describe "with minimal fields" do
      let(:file) { "valid_minimal.csv" }

      it "is valid" do
        expect(class_import).to be_valid
        expect(class_import.rows.count).to eq(1)

        patient = class_import.rows.first.to_patient
        expect(patient).to have_attributes(
          given_name: "Jennifer",
          family_name: "Clarke",
          date_of_birth: Date.new(2010, 1, 1)
        )

        expect(
          class_import.rows.first.to_school_move(patient)
        ).to have_attributes(school: location)
      end
    end
  end

  describe "#process!" do
    subject(:process!) { class_import.process! }

    let(:file) { "valid.csv" }

    it "creates patients and parents" do
      # stree-ignore
      expect { process! }
        .to change(class_import, :processed_at).from(nil)
        .and change(class_import.patients, :count).by(4)
        .and change(class_import.parents, :count).by(5)

      expect(Patient.first).to have_attributes(
        nhs_number: "9990000018",
        date_of_birth: Date.new(2010, 1, 1),
        given_name: "Jennifer",
        family_name: "Clarke",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA",
        year_group: 9
      )

      expect(Patient.first.parents.count).to eq(1)

      expect(Patient.first.parents.first).to have_attributes(
        full_name: nil,
        phone: "07412 345678",
        email: "susan@example.com"
      )

      expect(Patient.second).to have_attributes(
        nhs_number: "9990000026",
        date_of_birth: Date.new(2010, 1, 2),
        given_name: "Jimmy",
        family_name: "Smith",
        school: location,
        address_line_1: "10 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA",
        year_group: 10
      )

      expect(Patient.second.parents.count).to eq(1)

      expect(Patient.second.parents.first).to have_attributes(
        full_name: "John Smith",
        phone: "07412 345678",
        email: "john@example.com"
      )

      expect(Patient.second.parent_relationships.first).to be_father

      expect(Patient.third).to have_attributes(
        nhs_number: "9990000034",
        date_of_birth: Date.new(2010, 1, 3),
        given_name: "Mark",
        family_name: "Doe",
        school: location,
        address_line_1: "11 Downing Street",
        address_town: "London",
        address_postcode: "SW1A 1AA",
        year_group: 10
      )

      expect(Patient.third.parents.count).to eq(2)

      expect(Patient.third.parents.first).to have_attributes(
        full_name: "Jane Doe",
        phone: "07412 345679",
        email: "jane@example.com"
      )

      expect(Patient.third.parents.second).to have_attributes(
        full_name: "Richard Doe",
        phone: nil,
        email: "richard@example.com"
      )

      expect(Patient.third.parent_relationships.first).to be_mother
      expect(Patient.third.parent_relationships.second).to be_father

      expect(Patient.fourth).to have_attributes(
        nhs_number: nil,
        date_of_birth: Date.new(2010, 4, 9),
        given_name: "Gae",
        family_name: "Thorne-Smith",
        school: location,
        address_line_1: nil,
        address_town: nil,
        address_postcode: nil,
        year_group: 10
      )

      expect(Patient.fourth.parents).not_to be_empty

      # Second import should not duplicate the patients if they're identical.

      # stree-ignore
      expect { class_import.process! }
        .to not_change(class_import, :processed_at)
        .and not_change(Patient, :count)
        .and not_change(Parent, :count)
    end

    it "stores statistics on the import" do
      # stree-ignore
      expect { process! }
        .to change(class_import, :exact_duplicate_record_count).to(0)
        .and change(class_import, :new_record_count).to(4)
        .and change(class_import, :changed_record_count).to(0)
    end

    it "ignores and counts duplicate records" do
      create(:class_import, csv:, organisation:, session:).process!
      csv.rewind

      process!
      expect(class_import.exact_duplicate_record_count).to eq(4)
    end

    it "enqueues jobs to look up missing NHS numbers" do
      expect { process! }.to have_enqueued_job(
        PatientNHSNumberLookupJob
      ).once.on_queue(:imports)
    end

    it "enqueues jobs to update from PDS" do
      expect { process! }.to have_enqueued_job(PatientUpdateFromPDSJob)
        .exactly(3)
        .times
        .on_queue(:imports)
    end

    context "with an existing patient matching the name" do
      let!(:patient) do
        create(
          :patient,
          given_name: "Jimmy",
          family_name: "Smith",
          date_of_birth: Date.new(2010, 1, 2),
          nhs_number: nil,
          parents: []
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(Patient, :count).by(3)
      end

      context "with an existing parent" do
        let!(:parent) do
          create(
            :parent,
            full_name: "John Smith",
            email: "john@example.com",
            phone: "07412345678"
          )
        end

        it "doesn't create an additional patient" do
          expect { process! }.to change(Parent, :count).by(4)

          parent_relationship = patient.reload.parent_relationships.first
          expect(parent_relationship.parent_id).to eq(parent.id)
          expect(parent_relationship).to be_father
        end
      end
    end

    context "with an existing patient matching the name but a different case" do
      before do
        create(
          :patient,
          given_name: "jimmy",
          family_name: "SMITH",
          date_of_birth: Date.new(2010, 1, 2),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(Patient, :count).by(3)
      end
    end

    context "with an existing parent matching the name but a different case" do
      let!(:existing_parent) do
        create(:parent, full_name: "JOHN smith", email: "john@example.com")
      end

      it "doesn't create an additional parent" do
        expect { process! }.to change(Parent, :count).by(4)
      end

      it "changes the parent's name to the incoming version" do
        process!
        expect(existing_parent.reload.full_name).to eq("John Smith")
      end
    end

    context "with an existing patient in a different school" do
      let(:patient) do
        create(
          :patient,
          nhs_number: "9990000018",
          school: create(:school),
          session: create(:session, programmes:)
        )
      end

      it "proposes a school move for the child" do
        expect(patient.school_moves).to be_empty

        expect { process! }.to change { patient.reload.school_moves.count }.by(
          1
        )

        school_move = patient.school_moves.first
        expect(school_move.school_id).to eq(session.location_id)
      end

      it "doesn't stage school changes" do
        expect { process! }.not_to change(patient, :pending_changes)
        expect(patient.pending_changes.keys).not_to include(
          :cohort_id,
          :home_educated,
          :organisation_id,
          :school_id
        )
      end
    end

    context "with an unscheduled session" do
      let(:session) do
        create(:session, :unscheduled, organisation:, programmes:, location:)
      end

      it "adds the patients to the session" do
        expect { process! }.to change(session.patients, :count).from(0).to(4)
      end
    end

    context "with a scheduled session" do
      let(:session) do
        create(:session, :scheduled, organisation:, programmes:, location:)
      end

      it "adds the patients to the session" do
        expect { process! }.to change(session.patients, :count).from(0).to(4)
      end
    end

    context "with an existing patient not in the class list" do
      let!(:existing_patient) do
        create(:patient, nhs_number: "9322774096", session:, year_group: 8)
      end

      it "proposes a school move for the child" do
        expect(existing_patient.school_moves).to be_empty

        expect { process! }.to change {
          existing_patient.reload.school_moves.count
        }.by(1)

        school_move = existing_patient.school_moves.first
        expect(school_move.school).to be_nil
        expect(school_move.home_educated).to be(false)
      end

      it "doesn't propose a move if patient already has a proposed move" do
        create(
          :school_move,
          :to_unknown_school,
          patient: existing_patient,
          organisation:
        )

        expect { process! }.not_to(
          change { existing_patient.reload.school_moves.count }
        )
      end

      it "doesn't propose a move if the patient is in a different year group" do
        existing_patient.update!(birth_academic_year: 7.to_birth_academic_year)

        expect { process! }.not_to(
          change { existing_patient.reload.school_moves.count }
        )
      end
    end

    context "with an existing twin" do
      # This matches the details of the first row of `valid.csv` except the given name and registration.
      let!(:twin) do
        create(
          :patient,
          session:,
          nhs_number: nil,
          date_of_birth: Date.new(2010, 1, 1),
          given_name: "Samuel",
          preferred_given_name: nil,
          family_name: "Clarke",
          school: location,
          address_line_1: "10 Downing Street",
          address_line_2: nil,
          address_town: "London",
          address_postcode: "SW1A 1AA",
          year_group: 9,
          registration: "XYZ"
        )
      end

      it "doesn't auto-accept changes for potential twins, but queues them for manual review" do
        expect { process! }.to change { twin.reload.pending_changes }.from(
          {}
        ).to(
          {
            "given_name" => "Jennifer",
            "preferred_given_name" => "Jenny",
            "nhs_number" => "9990000018",
            "registration" => "ABC"
          }
        ).and not_change(twin, :given_name).and not_change(
                      twin,
                      :preferred_given_name
                    ).and not_change(twin, :nhs_number).and not_change(
                                  twin,
                                  :registration
                                )
      end
    end
  end
end
