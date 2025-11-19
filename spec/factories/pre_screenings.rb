# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_screenings
#
#  id                   :bigint           not null, primary key
#  date                 :date             not null
#  notes                :text             default(""), not null
#  programme_type       :enum             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  location_id          :bigint           not null
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#
# Indexes
#
#  index_pre_screenings_on_location_id           (location_id)
#  index_pre_screenings_on_patient_id            (patient_id)
#  index_pre_screenings_on_performed_by_user_id  (performed_by_user_id)
#  index_pre_screenings_on_programme_id          (programme_id)
#  index_pre_screenings_on_programme_type        (programme_type)
#  index_pre_screenings_on_session_date_id       (session_date_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_date_id => session_dates.id)
#
FactoryBot.define do
  factory :pre_screening do
    transient do
      session { association(:session) }
      session_date { session.session_dates.first }
    end

    patient
    location { session.location }
    date { session_date.value }
    programme { session_date.session.programmes.first }
    performed_by

    notes { "Fine to vaccinate" }
  end
end
