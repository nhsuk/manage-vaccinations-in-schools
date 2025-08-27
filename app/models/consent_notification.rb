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

  self.inheritance_column = nil

  belongs_to :patient
  belongs_to :session

  has_one :team, through: :session

  has_many :consent_notification_programmes,
           -> { joins(:programme).order(:"programmes.type") },
           dependent: :destroy

  has_many :programmes, through: :consent_notification_programmes

  delegate :academic_year, to: :session

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

    notification = ConsentNotification.create!(
      programmes:,
      patient:,
      session:,
      type:,
      sent_at: Time.current,
      sent_by: current_user
    )
    # write the denormalized events for Commissioner Reporting
    notification.create_or_update_reportable_consent_events

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

  def create_or_update_reportable_consent_events
    parents = patient.parents.select(&:contactable?)
    programmes.each do |programme|
      parents.each do |parent|
        event =
          ReportingAPI::ConsentEvent.find_or_initialize_by(
            source_id: id,
            source_type: self.class.name
          )
        event.event_timestamp = sent_at
        event.event_type = type

        event.copy_attributes_from_references(
          consent_notification: self,
          patient: patient,
          patient_school: patient.school,
          # patient_local_authority: patient&.local_authority_from_postcode,
          parent:,
          parent_relationship: patient.parent_relationships.find_by(parent_id: parent.id),
          programme:,
          team: session&.team,
          organisation: session&.team&.organisation 
        )

        event.save!
        event
      end
    end
  end

end
