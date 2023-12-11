# == Schema Information
#
# Table name: vaccination_records
#
#  id                 :bigint           not null, primary key
#  administered       :boolean
#  delivery_method    :integer
#  delivery_site      :integer
#  notes              :text
#  reason             :integer
#  recorded_at        :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  batch_id           :bigint
#  patient_session_id :bigint           not null
#  user_id            :bigint
#
# Indexes
#
#  index_vaccination_records_on_batch_id            (batch_id)
#  index_vaccination_records_on_patient_session_id  (patient_session_id)
#  index_vaccination_records_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (batch_id => batches.id)
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :vaccination_record do
    patient_session { nil }
    recorded_at { "2023-06-09" }
    delivery_site { "left_arm" }
    delivery_method { "intramuscular" }
    batch { patient_session.session.campaign.vaccines.first.batches.first }
  end
end
