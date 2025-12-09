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

  def self.create_and_send!(
    patient:,
    programmes:,
    team:,
    academic_year:,
    type:,
    current_user: nil
  )
    parents = patient.parents.select(&:contactable?).uniq
    return if parents.empty?

    programmes.reject! do |programme|
      patient.programme_status(programme, academic_year:).vaccinated_fully?
    end

    return if programmes.empty?

    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    ClinicNotification.create!(
      patient:,
      programmes:,
      team:,
      academic_year:,
      type:,
      sent_at: Time.current,
      sent_by: current_user
    )

    programme_types = programmes.map(&:type)
    organisation = team.organisation

    parents.each do |parent|
      params = {
        academic_year:,
        parent:,
        patient:,
        programme_types:,
        sent_by: current_user,
        team:
      }

      template_names = [
        :"clinic_#{type}_#{organisation.ods_code.downcase}",
        :"clinic_#{type}"
      ]

      template_name =
        template_names.find { GOVUK_NOTIFY_EMAIL_TEMPLATES.key?(it) }

      EmailDeliveryJob.perform_later(template_name, **params)
      SMSDeliveryJob.perform_later(template_name, **params)
    end
  end
end
