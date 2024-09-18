# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                       :bigint           not null, primary key
#  administered_at          :datetime
#  delivery_method          :integer
#  delivery_site            :integer
#  dose_sequence            :integer          not null
#  notes                    :text
#  pending_changes          :jsonb            not null
#  performed_by_family_name :string
#  performed_by_given_name  :string
#  reason                   :integer
#  recorded_at              :datetime
#  uuid                     :uuid             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  batch_id                 :bigint
#  patient_session_id       :bigint           not null
#  performed_by_user_id     :bigint
#  vaccine_id               :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id              (batch_id)
#  index_vaccination_records_on_patient_session_id    (patient_session_id)
#  index_vaccination_records_on_performed_by_user_id  (performed_by_user_id)
#  index_vaccination_records_on_vaccine_id            (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#

describe VaccinationRecord, type: :model do
  subject(:vaccination_record) { create(:vaccination_record, programme:) }

  let(:programme) do
    create(
      :programme,
      :active,
      academic_year: 2020,
      start_date: Date.new(2020, 1, 1),
      end_date: Date.new(2020, 12, 31)
    )
  end

  describe "validations" do
    it "is expected to validate that :administered_at is between the programme start and end date" do
      expect(vaccination_record).to validate_comparison_of(
        :administered_at
      ).is_greater_than_or_equal_to(Time.zone.local(2020, 1, 1)).is_less_than(
        Time.zone.local(2021, 1, 1)
      )
    end

    context "vaccine and batch doesn't match" do
      subject(:vaccination_record) do
        build(:vaccination_record, vaccine:, batch:, patient_session:)
      end

      let(:patient_session) { create(:patient_session) }
      let(:vaccine) { patient_session.programme.vaccines.first }
      let(:different_vaccine) { create(:vaccine) }
      let(:batch) { create(:batch, vaccine: different_vaccine) }

      it "has an error" do
        expect(vaccination_record).to be_invalid
        expect(vaccination_record.errors[:batch_id]).to include(
          "Choose a batch of the #{vaccine.brand} vaccine"
        )
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
          full_name: "John Smith",
          given_name: "John",
          family_name: "Smith"
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
end
