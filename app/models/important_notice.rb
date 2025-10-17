# frozen_string_literal: true

# == Schema Information
#
# Table name: important_notices
#
#  id                    :bigint           not null, primary key
#  can_dismiss           :boolean          default(FALSE)
#  date_time             :datetime
#  dismissed_at          :datetime
#  message               :text
#  notice_type           :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  dismissed_by_user_id  :bigint
#  patient_id            :bigint           not null
#  team_id               :bigint           not null
#  vaccination_record_id :bigint
#
# Indexes
#
#  index_important_notices_on_dismissed_by_user_id          (dismissed_by_user_id)
#  index_important_notices_on_patient_id                    (patient_id)
#  index_important_notices_on_team_id                       (team_id)
#  index_important_notices_on_vaccination_record_id         (vaccination_record_id)
#  index_notices_on_patient_and_type_and_datetime_and_team  (patient_id,notice_type,date_time,team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (dismissed_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccination_record_id => vaccination_records.id)
#
class ImportantNotice < ApplicationRecord
  belongs_to :patient

  enum :notice_type,
       { deceased: 0, invalidated: 1, restricted: 2, gillick_no_notify: 3 }

  scope :active, ->(team:) { where(dismissed_at: nil, team_id: team.id) }
  scope :dismissed,
        ->(team:) { where.not(dismissed_at: nil).where(team_id: team.id) }

  scope :latest_for_patient,
        ->(patient:) do
          notices = where(patient: patient)
          [
            (
              if patient.restricted?
                notices.restricted.order(date_time: :desc).first
              end
            ),
            (
              if patient.invalidated?
                notices.invalidated.order(date_time: :desc).first
              end
            ),
            *notices.deceased,
            *notices.gillick_no_notify
          ].compact
        end

  validates :notice_type, presence: true
  validates :date_time, presence: true
  validates :message, presence: true

  def dismiss!(user: nil)
    update!(dismissed_at: Time.current, dismissed_by_user_id: user&.id)
  end
end
