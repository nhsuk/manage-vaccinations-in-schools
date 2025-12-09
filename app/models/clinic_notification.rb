# frozen_string_literal: true

# == Schema Information
#
# Table name: clinic_notifications
#
#  id              :bigint           not null, primary key
#  academic_year   :integer          not null
#  programme_types :enum             not null, is an Array
#  sent_at         :datetime         not null
#  type            :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  patient_id      :bigint           not null
#  sent_by_user_id :bigint
#  team_id         :bigint           not null
#
# Indexes
#
#  index_clinic_notifications_on_patient_id       (patient_id)
#  index_clinic_notifications_on_sent_by_user_id  (sent_by_user_id)
#  index_clinic_notifications_on_team_id          (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (team_id => teams.id)
#
class ClinicNotification < ApplicationRecord
  include HasManyProgrammes
  include Sendable

  self.inheritance_column = nil

  belongs_to :patient
  belongs_to :team

  enum :type,
       { initial_invitation: 0, subsequent_invitation: 1 },
       validate: true
end
