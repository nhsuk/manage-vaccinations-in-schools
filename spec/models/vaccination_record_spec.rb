# frozen_string_literal: true

# == Schema Information
#
# Table name: vaccination_records
#
#  id                 :bigint           not null, primary key
#  administered       :boolean
#  delivery_method    :integer
#  delivery_site      :integer
#  dose_sequence      :integer          not null
#  exported_to_dps_at :datetime
#  notes              :text
#  reason             :integer
#  recorded_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  batch_id           :bigint
#  imported_from_id   :bigint
#  patient_session_id :bigint           not null
#  user_id            :bigint
#  vaccine_id         :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id            (batch_id)
#  index_vaccination_records_on_imported_from_id    (imported_from_id)
#  index_vaccination_records_on_patient_session_id  (patient_session_id)
#  index_vaccination_records_on_user_id             (user_id)
#  index_vaccination_records_on_vaccine_id          (vaccine_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (imported_from_id => immunisation_imports.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (vaccine_id => vaccines.id)
#
require "rails_helper"

describe VaccinationRecord do
  it "validates that the vaccine and the batch vaccines match" do
    patient_session = create(:patient_session)
    vaccine = create(:vaccine, :hpv)
    different_vaccine = create(:vaccine, :flu)
    batch = create(:batch, vaccine: different_vaccine)

    subject =
      build(
        :vaccination_record,
        administered: true,
        vaccine:,
        batch:,
        patient_session:
      )

    expect(subject).not_to be_valid
    expect(subject.errors[:batch_id]).to include(
      "Choose a batch of the #{vaccine.brand} vaccine"
    )
  end
end
