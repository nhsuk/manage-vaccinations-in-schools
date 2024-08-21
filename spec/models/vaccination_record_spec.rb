# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                   :bigint           not null, primary key
#  administered_at      :datetime
#  delivery_method      :integer
#  delivery_site        :integer
#  dose_sequence        :integer          not null
#  notes                :text
#  reason               :integer
#  recorded_at          :datetime
#  uuid                 :uuid             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  batch_id             :bigint
#  imported_from_id     :bigint
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint
#  vaccine_id           :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id              (batch_id)
#  index_vaccination_records_on_imported_from_id      (imported_from_id)
#  index_vaccination_records_on_patient_session_id    (patient_session_id)
#  index_vaccination_records_on_performed_by_user_id  (performed_by_user_id)
#  index_vaccination_records_on_vaccine_id            (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
require "rails_helper"

describe VaccinationRecord, type: :model do
  subject(:vaccination_record) do
    create(
      :vaccination_record,
      patient_session:
        create(:patient_session, session_attributes: { campaign: })
    )
  end

  let(:campaign) do
    create(
      :campaign,
      :active,
      academic_year: 2020,
      start_date: Date.new(2020, 1, 1),
      end_date: Date.new(2020, 12, 31)
    )
  end

  describe "validations" do
    it "is expected to validate that :administered_at is between the campaign start and end date" do
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
      let(:vaccine) { patient_session.campaign.vaccines.first }
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
end
