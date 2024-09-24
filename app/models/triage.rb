# frozen_string_literal: true

# == Schema Information
#
# Table name: triage
#
#  id                   :bigint           not null, primary key
#  notes                :text             default(""), not null
#  status               :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_session_id   :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#
# Indexes
#
#  index_triage_on_patient_session_id    (patient_session_id)
#  index_triage_on_performed_by_user_id  (performed_by_user_id)
#  index_triage_on_programme_id          (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#
class Triage < ApplicationRecord
  audited associated_with: :patient_session

  belongs_to :patient_session
  belongs_to :programme

  belongs_to :performed_by,
             class_name: "User",
             foreign_key: :performed_by_user_id

  has_one :patient, through: :patient_session
  has_one :session, through: :patient_session

  enum :status,
       %i[
         ready_to_vaccinate
         do_not_vaccinate
         needs_follow_up
         delay_vaccination
       ],
       validate: true

  encrypts :notes

  validates :notes, length: { maximum: 1000 }
end
