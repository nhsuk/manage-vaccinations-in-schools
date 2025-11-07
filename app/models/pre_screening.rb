# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_screenings
#
#  id                   :bigint           not null, primary key
#  notes                :text             default(""), not null
#  programme_type       :enum
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#  session_date_id      :bigint           not null
#
# Indexes
#
#  index_pre_screenings_on_patient_id            (patient_id)
#  index_pre_screenings_on_performed_by_user_id  (performed_by_user_id)
#  index_pre_screenings_on_programme_id          (programme_id)
#  index_pre_screenings_on_session_date_id       (session_date_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (session_date_id => session_dates.id)
#
class PreScreening < ApplicationRecord
  include BelongsToSessionDate
  include Notable
  include PerformableByUser

  audited associated_with: :patient

  belongs_to :patient
  belongs_to :programme
end
