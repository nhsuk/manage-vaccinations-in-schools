# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id              :bigint           not null, primary key
#  programme_types :enum             not null, is an Array
#  sent_at         :datetime         not null
#  type            :integer          not null
#  patient_id      :bigint           not null
#  sent_by_user_id :bigint
#  session_id      :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id       (patient_id)
#  index_consent_notifications_on_programme_types  (programme_types) USING gin
#  index_consent_notifications_on_sent_by_user_id  (sent_by_user_id)
#  index_consent_notifications_on_session_id       (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (session_id => sessions.id)
#
class ConsentNotification < ApplicationRecord
  include HasManyProgrammes
  include Sendable

  self.inheritance_column = nil

  belongs_to :patient
  belongs_to :session

  has_one :team, through: :session

  delegate :academic_year, to: :session

  enum :type,
       { request: 0, initial_reminder: 1, subsequent_reminder: 2 },
       validate: true

  scope :reminder, -> { initial_reminder.or(subsequent_reminder) }

  def reminder? = initial_reminder? || subsequent_reminder?

  def sent_by_user? = sent_by != nil

  def sent_by_background_job? = sent_by.nil?

  def automated_reminder? = sent_by_background_job? && reminder?

  def manual_reminder? = sent_by_user? && reminder?

  def self.create_and_send!(
    patient:,
    programmes:,
    session:,
    type:,
    current_user: nil
  )
    parents = patient.parents.select(&:contactable?)

    return if parents.empty?

    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    ConsentNotification.create!(
      programmes:,
      patient:,
      session:,
      type:,
      sent_at: Time.current,
      sent_by: current_user
    )

    is_school = session.location.school?

    template = :"consent_#{(is_school ? :"school_#{type}" : :"clinic_#{type}")}"

    mail_template =
      if is_school
        group = ProgrammeGrouper.call(programmes).first.first
        :"#{template}_#{group}"
      else
        template
      end

    text_template =
      if type == :request
        template
      elsif is_school
        :consent_school_reminder
      end

    programme_types = programmes.map(&:type)

    parents.each do |parent|
      EmailDeliveryJob.perform_later(
        mail_template,
        parent:,
        patient:,
        programme_types:,
        session:,
        sent_by: current_user
      )

      SMSDeliveryJob.perform_later(
        text_template,
        parent:,
        patient:,
        programme_types:,
        session:,
        sent_by: current_user
      )
    end
  end
end
