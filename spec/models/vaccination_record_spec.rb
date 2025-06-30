# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                       :bigint           not null, primary key
#  confirmation_sent_at     :datetime
#  delivery_method          :integer
#  delivery_site            :integer
#  discarded_at             :datetime
#  dose_sequence            :integer
#  full_dose                :boolean
#  location_name            :string
#  notes                    :text
#  outcome                  :integer          not null
#  pending_changes          :jsonb            not null
#  performed_at             :datetime         not null
#  performed_by_family_name :string
#  performed_by_given_name  :string
#  performed_ods_code       :string
#  uuid                     :uuid             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  batch_id                 :bigint
#  patient_id               :bigint
#  performed_by_user_id     :bigint
#  programme_id             :bigint           not null
#  session_id               :bigint
#  vaccine_id               :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id              (batch_id)
#  index_vaccination_records_on_discarded_at          (discarded_at)
#  index_vaccination_records_on_patient_id            (patient_id)
#  index_vaccination_records_on_performed_by_user_id  (performed_by_user_id)
#  index_vaccination_records_on_programme_id          (programme_id)
#  index_vaccination_records_on_session_id            (session_id)
#  index_vaccination_records_on_uuid                  (uuid) UNIQUE
#  index_vaccination_records_on_vaccine_id            (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#

describe VaccinationRecord do
  subject(:vaccination_record) { build(:vaccination_record) }

  describe "validations" do
    context "when administered" do
      it { should allow_values(true, false).for(:full_dose) }
      it { should_not allow_values(nil).for(:full_dose) }
    end

    context "when not administered" do
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
      let(:organisation) { create(:organisation, programmes: [programme]) }
      let(:session) { organisation.generic_clinic_session }

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

  describe '#create_or_update_reportable_vaccination_event' do
    let!(:patient) { create(:patient, date_of_birth: Date.new(2011, 8, 21) ) }

    let!(:vaccination_record) do
      create(
        :vaccination_record,
        :performed_by_not_user,
        patient: patient,
        performed_at: Time.new(2024, 9, 10, 8, 55, 1),
        performed_by_given_name: "John",
        performed_by_family_name: "Smith"
      )
    end

    context 'when no ReportableVaccinationEvent record exists for this VaccinationRecord' do
      it 'creates a new ReportableVaccinationEvent' do
        expect{ vaccination_record.create_or_update_reportable_vaccination_event }.to change(ReportableVaccinationEvent, :count).by(1)
      end

      describe "the new record" do
        let(:new_record) { vaccination_record.create_or_update_reportable_vaccination_event }

        it "has this vaccination_record as source" do
          expect(new_record.source).to eq(vaccination_record)
        end

        it "has the performed_at as event_timestamp" do
          expect(new_record.event_timestamp).to eq(vaccination_record.performed_at)
        end

        it "has the outcome as the event_type" do
          expect(new_record.event_type).to eq(vaccination_record.outcome)
        end

        it "has a copy of the patient attributes" do
          %w[
            address_postcode
            address_town
            birth_academic_year
            date_of_birth
            date_of_death
            home_educated
            nhs_number
          ].each do |attr_name|
            expect( new_record[["patient", attr_name].join("_")] ).to eq(vaccination_record.patient[attr_name])
          end
        end

        it "calculates the correct year_group for the patient" do
          expect(new_record.patient_year_group).to eq(9)
        end
      end
    end

    context 'when a ReportableVaccinationEvent exists for this VaccinationRecord' do
      before do
        ReportableVaccinationEvent.create!(source_id: vaccination_record.id, source_type: 'VaccinationRecord', event_timestamp: Time.current - 1.day)
      end

      it 'does not create a new ReportableVaccinationEvent' do
        expect{ vaccination_record.create_or_update_reportable_vaccination_event }.not_to change(ReportableVaccinationEvent, :count)
      end
    end
  end
end
