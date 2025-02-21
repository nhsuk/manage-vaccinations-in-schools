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
#  dose_sequence            :integer          not null
#  location_name            :string
#  notes                    :text
#  outcome                  :integer          not null
#  pending_changes          :jsonb            not null
#  performed_at             :datetime         not null
#  performed_by_family_name :string
#  performed_by_given_name  :string
#  performed_ods_code       :string           not null
#  uuid                     :uuid             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  batch_id                 :bigint
#  patient_id               :bigint
#  performed_by_user_id     :bigint
#  programme_id             :bigint           not null
#  session_id               :bigint
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
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_id => sessions.id)
#

describe VaccinationRecord do
  subject(:vaccination_record) { build(:vaccination_record) }

  describe "validations" do
    context "for a school session" do
      subject(:vaccination_record) do
        build(:vaccination_record, programme:, session:)
      end

      let(:programme) { create(:programme) }
      let(:session) { create(:session, programme: programme) }

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

    context "when administered is false and dose_sequence is not 1" do
      let(:vaccination_record) do
        build(:vaccination_record, outcome: :refused, dose_sequence: 2)
      end

      it "is valid" do
        expect(vaccination_record).to be_valid
      end
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
          family_name: "Smith"
        )
        expect(performed_by.full_name).to eq("SMITH, John")
      end
    end

    context "without a user or a name" do
      let(:vaccination_record) do
        create(:vaccination_record, performed_by: nil)
      end

      it { should be_nil }
    end
  end
end
