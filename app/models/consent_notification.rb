# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id              :bigint           not null, primary key
#  sent_at         :datetime         not null
#  type            :integer          not null
#  patient_id      :bigint           not null
#  sent_by_user_id :bigint
#  session_id      :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id       (patient_id)
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
  include Sendable

  self.inheritance_column = :nil

  belongs_to :patient
  belongs_to :session

  has_one :organisation, through: :session

  has_many :consent_notification_programmes,
           -> { joins(:programme).order(:"programmes.type") },
           dependent: :destroy

  has_many :programmes, through: :consent_notification_programmes

  enum :type,
       { request: 0, initial_reminder: 1, subsequent_reminder: 2 },
       validate: true

  scope :has_programme,
        ->(programme) { joins(:programmes).where(programmes: programme) }

  scope :reminder, -> { initial_reminder.or(subsequent_reminder) }

  def reminder?
    initial_reminder? || subsequent_reminder?
  end

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

    parents.each do |parent|
      EmailDeliveryJob.perform_later(
        mail_template,
        parent:,
        patient:,
        programmes:,
        session:,
        sent_by: current_user
      )

      SMSDeliveryJob.perform_later(
        text_template,
        parent:,
        patient:,
        programmes:,
        session:,
        sent_by: current_user
      )
    end
  end
end
