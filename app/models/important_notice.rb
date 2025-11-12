# frozen_string_literal: true

# == Schema Information
#
# Table name: important_notices
#
#  id                    :bigint           not null, primary key
#  dismissed_at          :datetime
#  recorded_at           :datetime         not null
#  type                  :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  dismissed_by_user_id  :bigint
#  patient_id            :bigint           not null
#  team_id               :bigint           not null
#  vaccination_record_id :bigint
#
# Indexes
#
#  index_important_notices_on_dismissed_by_user_id             (dismissed_by_user_id)
#  index_important_notices_on_patient_id                       (patient_id)
#  index_important_notices_on_team_id                          (team_id)
#  index_important_notices_on_vaccination_record_id            (vaccination_record_id)
#  index_notices_on_patient_and_type_and_recorded_at_and_team  (patient_id,type,recorded_at,team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (dismissed_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (vaccination_record_id => vaccination_records.id)
#
class ImportantNotice < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :patient

  belongs_to :vaccination_record, optional: true

  enum :type,
       { deceased: 0, invalidated: 1, restricted: 2, gillick_no_notify: 3 }

  scope :active, ->(team:) { where(dismissed_at: nil, team_id: team.id) }
  scope :dismissed,
        ->(team:) { where.not(dismissed_at: nil).where(team_id: team.id) }

  validates :type, presence: true
  validates :recorded_at, presence: true
  validates :message, presence: true

  def dismiss!(user: nil)
    update!(dismissed_at: Time.current, dismissed_by_user_id: user&.id)
  end

  def message
    case type
    when "deceased"
      "Record updated with child’s date of death"
    when "invalidated"
      "Record flagged as invalid"
    when "restricted"
      "Record flagged as sensitive"
    when "gillick_no_notify"
      "Child gave consent for #{vaccination_record.programme.name} under Gillick competence and " \
        "does not want their parents to be notified. " \
        "These records will not be automatically synced with GP records. " \
        "Your team must let the child's GP know they were vaccinated."
    else
      "Important notice"
    end
  end

  def can_dismiss?
    type.in?(%w[deceased restricted gillick_no_notify])
  end
end
