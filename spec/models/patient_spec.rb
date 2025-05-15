# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                        :bigint           not null, primary key
#  address_line_1            :string
#  address_line_2            :string
#  address_postcode          :string
#  address_town              :string
#  birth_academic_year       :integer          not null
#  date_of_birth             :date             not null
#  date_of_death             :date
#  date_of_death_recorded_at :datetime
#  family_name               :string           not null
#  gender_code               :integer          default("not_known"), not null
#  given_name                :string           not null
#  home_educated             :boolean
#  invalidated_at            :datetime
#  nhs_number                :string
#  pending_changes           :jsonb            not null
#  preferred_family_name     :string
#  preferred_given_name      :string
#  registration              :string
#  restricted_at             :datetime
#  updated_from_pds_at       :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  gp_practice_id            :bigint
#  organisation_id           :bigint
#  school_id                 :bigint
#
# Indexes
#
#  index_patients_on_family_name_trigram  (family_name) USING gin
#  index_patients_on_given_name_trigram   (given_name) USING gin
#  index_patients_on_gp_practice_id       (gp_practice_id)
#  index_patients_on_names_family_first   (family_name,given_name)
#  index_patients_on_names_given_first    (given_name,family_name)
#  index_patients_on_nhs_number           (nhs_number) UNIQUE
#  index_patients_on_organisation_id      (organisation_id)
#  index_patients_on_school_id            (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (gp_practice_id => locations.id)
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (school_id => locations.id)
#

describe Patient do
  describe "scopes" do
    describe "#search_by_name" do
      subject(:scope) { described_class.search_by_name(query) }

      let(:patient_a) do
        # exact match comes first
        create(:patient, given_name: "Harry", family_name: "Potter")
      end
      let(:patient_b) do
        # similar match comes next
        create(:patient, given_name: "Hari", family_name: "Potte")
      end
      let(:patient_c) do
        # least similar match comes last
        create(:patient, given_name: "Arry", family_name: "Pott")
      end
      let(:patient_d) do
        # no match isn't returned
        create(:patient, given_name: "Ron", family_name: "Weasley")
      end

      context "with full name, in `given_name family_name` format" do
        let(:query) { "Harry Potter" }

        it "returns the patients in the correct order" do
          expect(scope).to eq([patient_a, patient_b, patient_c])
        end
      end

      context "with exact name, in `FAMILY_NAME, given_name` format" do
        let(:query) { "POTTER, Harry" }

        it "returns the patients in the correct order" do
          expect(scope).to eq([patient_a, patient_b, patient_c])
        end
      end

      context "with exact name, in `family_name given_name` format" do
        let(:query) { "Potter Harry" }

        it "returns the patients in the correct order" do
          expect(scope).to eq([patient_a, patient_b, patient_c])
        end
      end

      context "with last name only" do
        let(:query) { "Potter" }

        it "returns the patients in the correct order" do
          expect(scope).to eq([patient_a, patient_b, patient_c])
        end
      end

      context "with first name only" do
        let(:query) { "Harry" }

        it "returns the patients in the correct order" do
          expect(scope).to eq([patient_a])
        end
      end
    end

    describe "#order_by_name" do
      subject(:scope) { described_class.order_by_name }

      let(:patient_a) { create(:patient, family_name: "Adams") }
      let(:patient_b) do
        create(:patient, given_name: "christine", family_name: "Jones")
      end
      let(:patient_c) do
        create(:patient, given_name: "claire", family_name: "Jones")
      end

      it { should eq([patient_a, patient_b, patient_c]) }
    end
  end

  describe "validations" do
    context "when home educated" do
      subject(:patient) { build(:patient, :home_educated) }

      it { should validate_absence_of(:school) }
    end

    context "with an invalid GP practice" do
      subject(:patient) { build(:patient, gp_practice: create(:school)) }

      it "is invalid" do
        expect(patient.valid?).to be(false)
        expect(patient.errors[:gp_practice]).to include(
          "must be a GP practice location type"
        )
      end
    end

    context "with an invalid school" do
      subject(:patient) { build(:patient, school: create(:community_clinic)) }

      it "is invalid" do
        expect(patient.valid?).to be(false)
        expect(patient.errors[:school]).to include(
          "must be a school location type"
        )
      end
    end
  end

  describe "#vaccination_records" do
    subject(:vaccination_records) { patient.vaccination_records }

    let(:patient) { create(:patient) }
    let(:programme) { create(:programme) }
    let(:kept_vaccination_record) do
      create(:vaccination_record, patient:, programme:)
    end
    let(:discarded_vaccination_record) do
      create(:vaccination_record, :discarded, patient:, programme:)
    end

    it { should include(kept_vaccination_record) }
    it { should_not include(discarded_vaccination_record) }
  end

  it { should normalize(:nhs_number).from(" 0123456789 ").to("0123456789") }
  it { should normalize(:address_postcode).from(" SW111AA ").to("SW11 1AA") }

  describe "#match_existing" do
    subject(:match_existing) do
      described_class.match_existing(
        nhs_number:,
        given_name:,
        family_name:,
        date_of_birth:,
        address_postcode:
      )
    end

    let(:nhs_number) { "0123456789" }
    let(:given_name) { "John" }
    let(:family_name) { "Smith" }
    let(:date_of_birth) { Date.new(1999, 1, 1) }
    let(:address_postcode) { "SW1A 1AA" }

    context "with no matches" do
      let(:patient) { create(:patient) }

      it { should_not include(patient) }
    end

    context "with a matching NHS number" do
      let!(:patient) { create(:patient, nhs_number:) }

      it { should include(patient) }

      context "when other patients match too" do
        let(:other_patient) do
          create(
            :patient,
            nhs_number: nil,
            given_name:,
            family_name:,
            date_of_birth:
          )
        end

        it { should_not include(other_patient) }
      end
    end

    context "with matching first name, last name and date of birth" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, given_name:, family_name:, date_of_birth:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and date of birth and postcode not provided" do
      let(:nhs_number) { nil }
      let(:address_postcode) { nil }
      let(:patient) do
        create(:patient, given_name:, family_name:, date_of_birth:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, given_name:, family_name:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and postcode not provided" do
      let(:nhs_number) { nil }
      let(:address_postcode) { nil }
      let(:patient) do
        create(:patient, given_name:, family_name:, address_postcode: nil)
      end

      it { should_not include(patient) }
    end

    context "with matching first name, date of birth and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, given_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching last name, date of birth and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, family_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and date of birth but names are uppercase" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(
          :patient,
          given_name: given_name.upcase,
          family_name: family_name.upcase,
          date_of_birth:
        )
      end

      it { should include(patient) }
    end

    context "when matching everything except the NHS number" do
      let(:other_patient) do
        create(
          :patient,
          nhs_number: "9876543210",
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode:
        )
      end

      it { should_not include(other_patient) }
    end
  end

  describe "#initials" do
    subject(:initials) { patient.initials }

    let(:patient) { create(:patient, given_name: "John", family_name: "Doe") }

    it { should eq("JD") }
  end

  describe "#update_from_pds!" do
    subject(:update_from_pds!) { patient.update_from_pds!(pds_patient) }

    let(:patient) { create(:patient, nhs_number: "0123456789") }
    let(:pds_patient) { PDS::Patient.new(nhs_number: "0123456789") }

    it "doesn't set a date of death" do
      expect { update_from_pds! }.not_to change(patient, :date_of_death)
    end

    it "doesn't flag as restricted" do
      expect { update_from_pds! }.not_to change(patient, :restricted_at)
    end

    it "doesn't change the GP practice" do
      expect { update_from_pds! }.not_to change(patient, :gp_practice)
    end

    it "sets the updated from PDS date and time" do
      freeze_time do
        expect { update_from_pds! }.to change(
          patient,
          :updated_from_pds_at
        ).from(nil).to(Time.current)
      end
    end

    context "when the NHS number doesn't match" do
      let(:pds_patient) { PDS::Patient.new(nhs_number: "abc") }

      it "raises an error" do
        expect { update_from_pds! }.to raise_error(Patient::NHSNumberMismatch)
      end
    end

    context "with notification of death" do
      let(:pds_patient) do
        PDS::Patient.new(
          nhs_number: "0123456789",
          date_of_death: Date.new(2024, 1, 1)
        )
      end

      it "sets the date of death" do
        expect { update_from_pds! }.to change(patient, :date_of_death).to(
          Date.new(2024, 1, 1)
        )
      end

      it "sets the date of death recorded at" do
        freeze_time do
          expect { update_from_pds! }.to change(
            patient,
            :date_of_death_recorded_at
          ).from(nil).to(Time.current)
        end
      end

      context "when in an upcoming session" do
        let(:session) { create(:session, :scheduled) }

        before { create(:patient_session, patient:, session:) }

        it "removes the patient from the session" do
          expect(session.patients).to include(patient)
          update_from_pds!
          expect(session.patients).not_to include(patient)
        end
      end
    end

    context "with a restricted flag" do
      let(:pds_patient) do
        PDS::Patient.new(nhs_number: "0123456789", restricted: true)
      end

      it "sets restricted at" do
        freeze_time do
          expect { update_from_pds! }.to change(patient, :restricted_at).from(
            nil
          ).to(Time.current)
        end
      end
    end

    context "with a GP practice ODS code" do
      let(:gp_practice) { create(:gp_practice) }

      let(:pds_patient) do
        PDS::Patient.new(
          nhs_number: "0123456789",
          gp_ods_code: gp_practice.ods_code
        )
      end

      it "sets the GP practice" do
        expect { update_from_pds! }.to change(patient, :gp_practice).from(
          nil
        ).to(gp_practice)
      end
    end

    context "with a GP practice that doesn't exist" do
      let(:pds_patient) do
        PDS::Patient.new(nhs_number: "0123456789", gp_ods_code: "GP")
      end

      it "records an error in Sentry" do
        expect(Sentry).to receive(:capture_exception).with(
          an_instance_of(Patient::UnknownGPPractice)
        )
        update_from_pds!
      end
    end

    context "when the patient is currently invalidated" do
      let(:patient) do
        create(:patient, :invalidated, school:, nhs_number: "0123456789")
      end

      let(:programme) { create(:programme) }
      let(:organisation) { create(:organisation, programmes: [programme]) }
      let(:school) { create(:school, organisation:) }
      let(:session) do
        create(:session, location: school, organisation:, programme:)
      end

      it "marks the patient as not invalidated" do
        expect { update_from_pds! }.to change(patient, :invalidated?).from(
          true
        ).to(false)
      end
    end
  end

  describe "#invalidate!" do
    subject(:invalidate!) { patient.invalidate! }

    let(:patient) { create(:patient) }

    it "marks the patient as invalidated" do
      expect { invalidate! }.to change(patient, :invalidated?).from(false).to(
        true
      )
    end

    it "sets the date/time of when the patient was invalidated" do
      freeze_time do
        expect { invalidate! }.to change(patient, :invalidated_at).from(nil).to(
          Time.current
        )
      end
    end
  end

  describe "#stage_changes" do
    let(:patient) { create(:patient, given_name: "John", family_name: "Doe") }

    it "stages new changes in pending_changes" do
      patient.stage_changes(given_name: "Jane", address_line_1: "123 New St")

      expect(patient.pending_changes).to eq(
        { "given_name" => "Jane", "address_line_1" => "123 New St" }
      )
    end

    it "does not stage unchanged attributes" do
      patient.stage_changes(given_name: "John", family_name: "Smith")

      expect(patient.pending_changes).to eq({ "family_name" => "Smith" })
    end

    it "updates the pending_changes attribute" do
      expect { patient.stage_changes(given_name: "Jane") }.to change {
        patient.reload.pending_changes
      }.from({}).to({ "given_name" => "Jane" })
    end

    it "does not update other attributes directly" do
      patient.stage_changes(given_name: "Jane", family_name: "Smith")

      expect(patient.given_name).to eq("John")
      expect(patient.family_name).to eq("Doe")
    end

    it "does not save any changes if no valid changes are provided" do
      expect { patient.stage_changes(given_name: "John") }.not_to(
        change { patient.reload.pending_changes }
      )
    end
  end

  describe "#with_pending_changes" do
    let(:patient) { create(:patient) }

    it "returns the patient with pending changes applied" do
      patient.stage_changes(given_name: "Jane")
      expect(patient.given_name_changed?).to be(false)

      changed_patient = patient.with_pending_changes
      expect(changed_patient.given_name_changed?).to be(true)
      expect(changed_patient.family_name_changed?).to be(false)
      expect(changed_patient.given_name).to eq("Jane")
    end
  end

  describe "#dup_for_pending_changes" do
    subject(:new_patient) { old_patient.dup_for_pending_changes }

    let(:old_patient) { create(:patient) }

    it { should be_valid }

    it "doesn't change the old patient" do
      new_patient
      expect(old_patient).not_to be_changed
    end

    it "clears the NHS number" do
      expect(new_patient.nhs_number).to be_nil
    end

    context "when the old patient has upcoming sessions" do
      let(:session) { create(:session) }

      before { create(:patient_session, patient: old_patient, session:) }

      it "adds the new patient to any upcoming sessions" do
        expect(new_patient.patient_sessions.size).to eq(1)
        expect(new_patient.patient_sessions.first.session).to eq(session)
      end
    end

    context "when the old patient has a school move to a school" do
      let(:school) { create(:school) }

      before { create(:school_move, :to_school, patient: old_patient, school:) }

      it "adds any school moves from the old patient" do
        expect(new_patient.school_moves.size).to eq(1)
        expect(new_patient.school_moves.first.school).to eq(school)
      end
    end

    context "when the old patient has a school move to an unknown school" do
      before { create(:school_move, :to_unknown_school, patient: old_patient) }

      it "adds any school moves from the old patient" do
        expect(new_patient.school_moves.size).to eq(1)
        expect(new_patient.school_moves.first.home_educated).to be(false)
      end
    end

    context "when the old patient has a school move to home-schooled" do
      before { create(:school_move, :to_home_educated, patient: old_patient) }

      it "adds any school moves from the old patient" do
        expect(new_patient.school_moves.size).to eq(1)
        expect(new_patient.school_moves.first.home_educated).to be(true)
      end
    end
  end

  describe "#destroy_childless_parents" do
    context "when parent has only one child" do
      let(:parent) { create(:parent) }
      let!(:patient) { create(:patient, parents: [parent]) }

      it "destroys the parent when the patient is destroyed" do
        expect { patient.destroy }.to change(Parent, :count).by(-1)
      end
    end

    context "when parent has multiple children" do
      let(:parent) { create(:parent) }
      let!(:patient) { create(:patient, parents: [parent]) }

      before { create(:patient, parents: [parent]) }

      it "does not destroy the parent when one patient is destroyed" do
        expect { patient.destroy }.not_to change(Parent, :count)
      end
    end

    context "when patient has multiple parents" do
      let!(:patient) { create(:patient, parents: create_list(:parent, 2)) }

      it "destroys only the childless parents" do
        expect { patient.destroy }.to change(Parent, :count).by(-2)
      end
    end
  end
end
