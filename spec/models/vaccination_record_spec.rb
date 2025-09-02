# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                                    :bigint           not null, primary key
#  confirmation_sent_at                  :datetime
#  delivery_method                       :integer
#  delivery_site                         :integer
#  discarded_at                          :datetime
#  dose_sequence                         :integer
#  full_dose                             :boolean
#  location_name                         :string
#  nhs_immunisations_api_etag            :string
#  nhs_immunisations_api_sync_pending_at :datetime
#  nhs_immunisations_api_synced_at       :datetime
#  notes                                 :text
#  notify_parents                        :boolean
#  outcome                               :integer          not null
#  pending_changes                       :jsonb            not null
#  performed_at                          :datetime         not null
#  performed_by_family_name              :string
#  performed_by_given_name               :string
#  performed_ods_code                    :string
#  protocol                              :integer
#  source                                :integer          not null
#  uuid                                  :uuid             not null
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  batch_id                              :bigint
#  location_id                           :bigint
#  nhs_immunisations_api_id              :string
#  patient_id                            :bigint           not null
#  performed_by_user_id                  :bigint
#  programme_id                          :bigint           not null
#  session_id                            :bigint
#  supplied_by_user_id                   :bigint
#  vaccine_id                            :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id                  (batch_id)
#  index_vaccination_records_on_discarded_at              (discarded_at)
#  index_vaccination_records_on_location_id               (location_id)
#  index_vaccination_records_on_nhs_immunisations_api_id  (nhs_immunisations_api_id) UNIQUE
#  index_vaccination_records_on_patient_id                (patient_id)
#  index_vaccination_records_on_performed_by_user_id      (performed_by_user_id)
#  index_vaccination_records_on_programme_id              (programme_id)
#  index_vaccination_records_on_session_id                (session_id)
#  index_vaccination_records_on_supplied_by_user_id       (supplied_by_user_id)
#  index_vaccination_records_on_uuid                      (uuid) UNIQUE
#  index_vaccination_records_on_vaccine_id                (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (supplied_by_user_id => users.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
describe VaccinationRecord do
  subject(:vaccination_record) { build(:vaccination_record) }

  describe "associations" do
    it { should have_one(:identity_check).autosave(true).dependent(:destroy) }
    it { should belong_to(:supplied_by).optional }
  end

  describe "validations" do
    it { should validate_inclusion_of(:protocol).in_array(%w[pgd psd]) }

    context "when administered" do
      before { vaccination_record.outcome = "administered" }

      it { should allow_values(true, false).for(:full_dose) }
      it { should_not allow_values(nil).for(:full_dose) }

      context "when administered in mavis" do
        before { vaccination_record.session = create(:session) }

        it { should validate_presence_of(:protocol) }
      end
    end

    context "when not administered" do
      before { vaccination_record.outcome = "already_had" }

      it { should_not validate_presence_of(:protocol) }

      it { should_not validate_presence_of(:full_dose) }
    end

    context "for a school session" do
      subject(:vaccination_record) do
        build(:vaccination_record, programme:, session:)
      end

      let(:programme) { create(:programme) }
      let(:session) { create(:session, programmes: [programme]) }

      it { should validate_absence_of(:location_name) }
    end

    context "for a generic clinic" do
      subject(:vaccination_record) do
        build(:vaccination_record, programme:, session:)
      end

      let(:programme) { create(:programme) }
      let(:team) do
        create(:team, :with_generic_clinic, programmes: [programme])
      end
      let(:session) do
        team.generic_clinic_session(academic_year: AcademicYear.current)
      end

      it { should validate_presence_of(:location_name) }
    end

    context "when performed_at is not set" do
      let(:vaccination_record) { build(:vaccination_record, performed_at: nil) }

      it { should be_valid }
    end

    context "when performed_at is in the future" do
      around { |example| freeze_time { example.run } }

      let(:vaccination_record) do
        build(:vaccination_record, performed_at: 1.second.from_now)
      end

      it "has an error" do
        expect(vaccination_record).to be_invalid
        expect(vaccination_record.errors[:performed_at]).to include(
          "Enter a time in the past"
        )
      end
    end
  end

  describe "#dose_volume_ml" do
    subject { vaccination_record.dose_volume_ml }

    let(:programme) { create(:programme) }

    let(:vaccine) { build(:vaccine, programme:, dose_volume_ml: 10) }

    context "when administered" do
      let(:vaccination_record) do
        build(:vaccination_record, programme:, vaccine:)
      end

      it { should eq(10) }
    end

    context "when not administered" do
      let(:vaccination_record) do
        build(:vaccination_record, :not_administered, programme:)
      end

      it { should be_nil }
    end

    context "with a half dose" do
      let(:vaccination_record) do
        build(:vaccination_record, :half_dose, programme:, vaccine:)
      end

      it { should eq(5) }
    end
  end

  describe "#performed_by" do
    subject(:performed_by) { vaccination_record.performed_by }

    context "with a user" do
      let(:user) { create(:user, given_name: "John", family_name: "Smith") }
      let(:vaccination_record) do
        create(:vaccination_record, performed_by: user)
      end

      it { should eq(user) }
    end

    context "without a user but with a name" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          :performed_by_not_user,
          performed_by_given_name: "John",
          performed_by_family_name: "Smith"
        )
      end

      it { should_not be_nil }

      it do
        expect(performed_by).to have_attributes(
          given_name: "John",
          family_name: "Smith",
          full_name: "SMITH, John"
        )
      end
    end

    context "without a user or a name" do
      let(:vaccination_record) do
        create(:vaccination_record, performed_by: nil)
      end

      it { should be_nil }
    end
  end

  describe "#show_in_academic_year?" do
    subject { vaccination_record.show_in_academic_year?(academic_year) }

    context "with a seasonal record performed in the 2023/24 academic year" do
      let(:programme) { create(:programme, :flu) }
      let(:vaccination_record) do
        build(
          :vaccination_record,
          programme:,
          performed_at: Time.zone.local(2023, 9, 1)
        )
      end

      context "in the 2023/24 academic year" do
        let(:academic_year) { 2023 }

        it { should be(true) }
      end

      context "in the 2024/25 academic year" do
        let(:academic_year) { 2024 }

        it { should be(false) }
      end
    end

    context "with a non-seasonal record performed in the 2023/24 academic year" do
      let(:programme) { create(:programme, :hpv) }
      let(:vaccination_record) do
        build(
          :vaccination_record,
          programme:,
          performed_at: Time.zone.local(2023, 9, 1)
        )
      end

      context "in the 2023/24 academic year" do
        let(:academic_year) { 2023 }

        it { should be(true) }
      end

      context "in the 2024/25 academic year" do
        let(:academic_year) { 2024 }

        it { should be(true) }
      end
    end
  end

  describe "#delivery_method_snomed_code" do
    subject(:delivery_method_snomed_code) do
      vaccination_record.delivery_method_snomed_code
    end

    context "when delivery_method is intramuscular" do
      let(:vaccination_record) do
        build(:vaccination_record, delivery_method: :intramuscular)
      end

      it { should eq "78421000" }
    end

    context "when delivery_method is subcutaneous" do
      let(:vaccination_record) do
        build(:vaccination_record, delivery_method: :subcutaneous)
      end

      it { should eq "34206005" }
    end

    context "when delivery_method is nasal spray" do
      let(:vaccination_record) do
        build(:vaccination_record, delivery_method: :nasal_spray)
      end

      it { should eq "46713006" }
    end

    context "when delivery_method is not set" do
      let(:vaccination_record) do
        build(:vaccination_record, delivery_method: nil)
      end

      it "raises an error" do
        expect { delivery_method_snomed_code }.to raise_error(StandardError)
      end
    end
  end

  describe "#delivery_method_snomed_term" do
    subject(:delivery_method_snomed_term) do
      vaccination_record.delivery_method_snomed_term
    end

    context "when delivery_method is intramuscular" do
      let(:vaccination_record) do
        build(:vaccination_record, delivery_method: :intramuscular)
      end

      it { should eq "Intramuscular" }
    end

    context "when delivery_method is subcutaneous" do
      let(:vaccination_record) do
        build(:vaccination_record, delivery_method: :subcutaneous)
      end

      it { should eq "Subcutaneous" }
    end

    context "when delivery_method is nasal spray" do
      let(:vaccination_record) do
        build(:vaccination_record, delivery_method: :nasal_spray)
      end

      it { should eq "Nasal" }
    end

    context "when delivery_method is not set" do
      let(:vaccination_record) do
        build(:vaccination_record, delivery_method: nil)
      end

      it "raises an error" do
        expect { delivery_method_snomed_term }.to raise_error(StandardError)
      end
    end
  end

  describe "#changes_need_to_be_synced_to_nhs_immunisations_api?" do
    subject do
      vaccination_record.send(
        :changes_need_to_be_synced_to_nhs_immunisations_api?
      )
    end

    let(:vaccination_record) { create(:vaccination_record) }

    context "when the update doesn't change any attributes" do
      before { vaccination_record.update!(notes: vaccination_record.notes) }

      it { should be_falsy }
    end

    context "when regular fields have been changed" do
      before { vaccination_record.update!(notes: "Updated notes") }

      it { should be_truthy }
    end

    context "when only nhs_immunisations_api_etag has been changed" do
      before do
        vaccination_record.update!(nhs_immunisations_api_etag: "new-etag")
      end

      it { should be_falsy }
    end

    context "when only nhs_immunisations_api_sync_pending_at has been changed" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: Time.current
        )
      end

      it { should be_falsy }
    end

    context "when only nhs_immunisations_api_synced_at has been changed" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_synced_at: Time.current
        )
      end

      it { should be_falsy }
    end

    context "when only nhs_immunisations_api_id has been changed" do
      before { vaccination_record.update!(nhs_immunisations_api_id: "new-id") }

      it { should be_falsy }
    end

    context "when both regular fields and nhs_immunisations_api fields have been changed" do
      before do
        vaccination_record.update!(
          notes: "Updated notes",
          nhs_immunisations_api_etag: "new-etag"
        )
      end

      it { should be_falsy }
    end

    context "when a regular field and multiple nhs_immunisations_api fields have been changed" do
      before do
        vaccination_record.update!(
          outcome: :refused,
          nhs_immunisations_api_etag: "new-etag",
          nhs_immunisations_api_sync_pending_at: Time.current
        )
      end

      it { should be_falsy }
    end
  end

  describe "#for_academic_year" do
    before { vaccination_record.save! }

    it "returns the correct records" do
      academic_year = vaccination_record.academic_year

      expect(described_class.for_academic_year(academic_year)).to include(
        vaccination_record
      )

      expect(
        described_class.for_academic_year(academic_year + 1)
      ).not_to include(vaccination_record)
    end
  end

  describe "#academic_year" do
    let(:examples) do
      {
        Date.new(2020, 9, 1) => 2020,
        Date.new(2021, 8, 31) => 2020,
        Date.new(2021, 9, 1) => 2021,
        Date.new(2022, 8, 31) => 2021
      }
    end

    examples.each do |date, academic_year|
      context "with #{date}" do
        before { vaccination_record[attribute] = date }

        it { expect(vaccination_record.academic_year).to eq(academic_year) }
      end
    end
  end

  describe "#create_or_update_reporting_api_vaccination_event" do
    let(:flu) { Programme.find_by_type('flu') || create(:programme, type: 'flu') }
    let(:programmes) { [flu] }
    let(:team) { create(:team, programmes:) }
    let(:session) { create(:session, team:, programmes:) }
    let(:school) { create(:school, gias_local_authority_code: 999999) }
    let(:patient) { create(:patient, address_postcode: "DH1 3LH", school: school) }
    let(:local_authority) { create(:local_authority, gss_code: "D000000001", gias_code: 999999) }
    let!(:local_authority_postcode) { create(:local_authority_postcode, gss_code: local_authority.gss_code, value: "DH1 3LH") }

    subject(:vaccination_record) { create(:vaccination_record, programme: flu, outcome: :not_well, session: session, location: school, patient: patient) }

    context "when a reporting_api_vaccination_event already exists with this vaccination_record as source" do
      let!(:existing_event) { create(:reporting_api_vaccination_event, source: vaccination_record, outcome: 'not_well') }

      before do
        vaccination_record.update!(outcome: :administered)
      end

      it "does not create a new reporting_api_vaccination_event" do
        expect{ vaccination_record.create_or_update_reporting_api_vaccination_event }.not_to change(ReportingAPI::VaccinationEvent, :count)
      end

      it "updates the existing reporting_api_vaccination_event" do
        vaccination_record.create_or_update_reporting_api_vaccination_event

        expect(existing_event.reload.vaccination_record_outcome).to eq('administered')
      end
    end

    context "when no reporting_api_vaccination_event exists with this vaccination_record as source" do
      it "creates a new reporting_api_vaccination_event" do
        expect{ vaccination_record.create_or_update_reporting_api_vaccination_event }.to change(ReportingAPI::VaccinationEvent, :count).by(1)
      end

      describe "the created VaccinationEvent" do
        before do 
          vaccination_record.create_or_update_reporting_api_vaccination_event
        end

        let(:event) { ReportingAPI::VaccinationEvent.find_by(source_id: vaccination_record.id) }

        it "has this vaccination_record as source" do
          expect(event.source).to eq(vaccination_record)
        end

        it "has the outcome as event_type" do
          expect(event.event_type).to eq(vaccination_record.outcome)
        end

        it "has performed_at as event_timestamp" do
          expect(event.event_timestamp).to eq(vaccination_record.performed_at)
        end

        describe "denormalized relation properties" do
          it "has patient_ attributes set" do
            expect(event).to have_attributes(
              patient_id: patient.id,
              patient_address_town: patient.address_town,
              patient_address_postcode: patient.address_postcode,
              patient_gender_code: patient.gender_code,
              patient_home_educated: patient.home_educated,
              patient_date_of_death: patient.date_of_death,
              patient_birth_academic_year: patient.birth_academic_year,
            )
          end

          it "has patient_school_ attributes set" do
            expect(event).to have_attributes(
              patient_school_id: school.id,
              patient_school_address_town: school.address_town,
              patient_school_address_postcode: school.address_postcode,
              patient_school_name: school.name,
              patient_school_gias_local_authority_code: school.gias_local_authority_code,
              patient_school_type: school.type,
            )
          end

          it "has patient_school_local_authority_ attributes set" do
            expect(event).to have_attributes(
              patient_school_local_authority_short_name: local_authority.short_name,
              patient_school_local_authority_mhclg_code: local_authority.mhclg_code,
            )
          end

          it "has patient_local_authority_from_postcode_ attributes set" do
            expect(event).to have_attributes(
              patient_local_authority_from_postcode_short_name: patient.local_authority_from_postcode.short_name,
              patient_local_authority_from_postcode_mhclg_code: patient.local_authority_from_postcode.mhclg_code,
            )
          end

          it "has location_ attributes set" do
            expect(event).to have_attributes(
              location_id: school.id,
              location_address_town: school.address_town,
              location_address_postcode: school.address_postcode,
              location_name: school.name,
              location_type: school.type,
            )
          end

          it "has location_local_authority_ attributes set" do
            expect(event).to have_attributes(
              location_local_authority_short_name: local_authority.short_name,
              location_local_authority_mhclg_code: local_authority.mhclg_code,
            )
          end

          it "has team_ attributes set" do
            expect(event).to have_attributes(
              team_id: team&.id,
              team_name: team&.name,
            )
          end

          it "has organisation_ attributes set" do
            expect(event).to have_attributes(
              organisation_id: team.organisation.id,
              organisation_ods_code: team.organisation.ods_code,
            )
          end

          it "has programme_ attributes set" do
            expect(event).to have_attributes(
              programme_id: flu.id,
              programme_type: flu.type,
            )
          end

          it "has vaccination_record_ attributes set" do
            expect(event).to have_attributes(
              vaccination_record_outcome: vaccination_record.outcome,
              vaccination_record_uuid: vaccination_record.uuid,
              vaccination_record_performed_at: vaccination_record.performed_at,
              vaccination_record_programme_id: vaccination_record.programme_id,
              vaccination_record_session_id: vaccination_record.session_id,
            )
          end
        end
      end
    end
    
  end
end
