# frozen_string_literal: true

# == Schema Information
#
# Table name: session_attendances
#
#  id              :bigint           not null, primary key
#  attending       :boolean          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  patient_id      :bigint           not null
#  session_date_id :bigint           not null
#
# Indexes
#
#  index_session_attendances_on_patient_id                      (patient_id)
#  index_session_attendances_on_patient_id_and_session_date_id  (patient_id,session_date_id) UNIQUE
#  index_session_attendances_on_session_date_id                 (session_date_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (session_date_id => session_dates.id)
#
FactoryBot.define do
  factory :session_attendance do
    transient { session { association(:session) } }

    patient
    session_date { session.session_dates.first }

    trait :present do
      attending { true }
    end

    trait :absent do
      attending { false }
    end
  end
end
