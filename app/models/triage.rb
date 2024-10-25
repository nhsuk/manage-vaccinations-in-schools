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
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#  team_id              :bigint           not null
#
# Indexes
#
#  index_triage_on_patient_id            (patient_id)
#  index_triage_on_performed_by_user_id  (performed_by_user_id)
#  index_triage_on_programme_id          (programme_id)
#  index_triage_on_team_id               (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#
class Triage < ApplicationRecord
  self.table_name = "triage"

  audited

  belongs_to :patient
  belongs_to :programme
  belongs_to :team

  belongs_to :performed_by,
             class_name: "User",
             foreign_key: :performed_by_user_id

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

  def process!
    return unless delay_vaccination?

    patient.patient_sessions.find_or_create_by!(
      session: team.generic_clinic_session
    )
  end
end
