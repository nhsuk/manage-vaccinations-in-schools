# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_screenings
#
#  id                   :bigint           not null, primary key
#  date                 :date             not null
#  disease_types        :enum             not null, is an Array
#  notes                :text             default(""), not null
#  programme_type       :enum             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  location_id          :bigint           not null
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#
# Indexes
#
#  index_pre_screenings_on_location_id           (location_id)
#  index_pre_screenings_on_patient_id            (patient_id)
#  index_pre_screenings_on_performed_by_user_id  (performed_by_user_id)
#  index_pre_screenings_on_programme_type        (programme_type)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#
class PreScreening < ApplicationRecord
  include BelongsToLocationAndDate
  include BelongsToPerformedByUser
  include BelongsToProgramme
  include Notable

  audited associated_with: :patient

  belongs_to :patient
end
