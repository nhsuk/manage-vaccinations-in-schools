# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_changesets
#
#  id                    :bigint           not null, primary key
#  data                  :jsonb
#  import_type           :string           not null
#  matched_on_nhs_number :boolean
#  pds_nhs_number        :string
#  pending_changes       :jsonb            not null
#  record_type           :integer          default(1), not null
#  row_number            :integer
#  status                :integer          default("pending"), not null
#  uploaded_nhs_number   :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  import_id             :bigint           not null
#  patient_id            :bigint
#  school_id             :bigint
#
# Indexes
#
#  index_patient_changesets_on_import      (import_type,import_id)
#  index_patient_changesets_on_patient_id  (patient_id)
#  index_patient_changesets_on_status      (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#
describe PatientChangeset do
  subject(:changeset) do
    described_class.from_import_row(
      row: import_row,
      import: create(:class_import),
      row_number: 1
    )
  end

  let(:valid_data) do
    {
      child_school_urn: "123456",
      child_first_name: "Jimmy",
      child_last_name: "Smith",
      child_date_of_birth: "2010-01-01",
      child_address_line_1: "10 Downing Street",
      child_postcode: "SW1A 1AA",
      child_nhs_number: "999 000 0026",
      parent_1_email: "john@example.com",
      parent_1_phone: "07412345678"
    }
  end

  let(:import_row) do
    instance_double(
      CohortImportRow,
      school: create(:school, urn: "123456"),
      import_attributes: patient_import_attributes,
      parent_1_import_attributes: {
        full_name: "John Smith",
        relationship: "Father",
        email: "john@example.com",
        phone: "07412345678"
      },
      parent_2_import_attributes: {
      },
      academic_year: AcademicYear.current,
      school_move_source: "import",
      home_educated: false
    )
  end

  let(:patient_import_attributes) do
    {
      address_line_1: valid_data[:child_address_line_1],
      address_postcode: valid_data[:child_postcode],
      date_of_birth: Date.parse(valid_data[:child_date_of_birth]),
      family_name: valid_data[:child_last_name],
      given_name: valid_data[:child_first_name],
      nhs_number: valid_data[:child_nhs_number]&.gsub(/\s/, "")
    }.compact
  end

  describe "#patient" do
    it "builds patient with normalized attributes" do
      patient = changeset.patient
      expect(patient).to have_attributes(
        given_name: "Jimmy",
        family_name: "Smith",
        date_of_birth: Date.new(2010, 1, 1),
        nhs_number: "9990000026",
        address_line_1: "10 Downing Street",
        address_postcode: "SW1A 1AA"
      )
    end

    context "with existing patient" do
      let!(:existing_patient) do
        create(:patient, nhs_number: "9990000026", given_name: "James")
      end

      it "updates existing patient" do
        patient = changeset.patient
        expect(patient).to eq(existing_patient)
        expect(patient.given_name).to eq("James")
      end
    end
  end

  describe "#parents" do
    it "builds parent with relationship" do
      parents = changeset.parents
      relationships = changeset.parent_relationships

      expect(parents.size).to eq(1)
      expect(parents.first).to have_attributes(
        full_name: "John Smith",
        email: "john@example.com"
      )

      expect(relationships.first).to have_attributes(type: "father")
    end
  end

  describe "#school_move" do
    context "with school change" do
      before do
        @existing_patient =
          create(:patient, nhs_number: "9990000026", school: create(:school))
      end

      it "creates school move record" do
        move = changeset.school_move
        expect(move.school.urn).to eq("123456")
      end
    end
  end
end
