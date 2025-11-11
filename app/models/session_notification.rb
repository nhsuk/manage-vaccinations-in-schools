# frozen_string_literal: true

# == Schema Information
#
# Table name: session_notifications
#
#  id              :bigint           not null, primary key
#  sent_at         :datetime         not null
#  session_date    :date             not null
#  type            :integer          not null
#  patient_id      :bigint           not null
#  sent_by_user_id :bigint
#  session_id      :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_session_id_session_date_f7f30a3aa3  (patient_id,session_id,session_date)
#  index_session_notifications_on_sent_by_user_id        (sent_by_user_id)
#  index_session_notifications_on_session_id             (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (session_id => sessions.id)
#
class SessionNotification < ApplicationRecord
  include Sendable

  self.inheritance_column = nil

  belongs_to :patient
  belongs_to :session

  enum :type,
       {
         school_reminder: 0,
         clinic_initial_invitation: 1,
         clinic_subsequent_invitation: 2
       },
       validate: true

  def clinic_invitation?
    clinic_initial_invitation? || clinic_subsequent_invitation?
  end

  def self.create_and_send!(
    patient:,
    session:,
    session_date:,
    type:,
    current_user: nil
  )
    academic_year = session.academic_year

    parents =
      if type == :school_reminder
        session
          .programmes_for(patient:)
          .flat_map do |programme|
            ConsentGrouper
              .call(
                patient.consents,
                programme_type: programme.type,
                academic_year:
              )
              .select(&:response_given?)
              .filter_map(&:parent)
          end
      else
        patient.parents.select(&:contactable?)
      end

    parents.select!(&:contactable?)
    parents.uniq!

    return if parents.empty?

    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    SessionNotification.create!(
      patient:,
      session:,
      session_date:,
      type:,
      sent_at: Time.current,
      sent_by: current_user
    )

    academic_year = session_date.academic_year

    programmes =
      if type == :school_reminder
        session
          .programmes_for(patient:)
          .select do |programme|
            patient.consent_given_and_safe_to_vaccinate?(
              programme:,
              academic_year:
            )
          end
      else
        session
          .programmes_for(patient:)
          .reject do |programme|
            patient.vaccination_status(programme:, academic_year:).vaccinated?
          end
      end

    parents.each do |parent|
      params = {
        parent:,
        patient:,
        programme_types: programmes.map(&:type),
        session:,
        sent_by: current_user
      }

      template_name = compute_template_name(type, session.organisation)

      EmailDeliveryJob.perform_later(template_name, **params)

      next if type == :school_reminder && !parent.phone_receive_updates

      SMSDeliveryJob.perform_later(template_name, **params)
    end
  end

  def self.compute_template_name(type, organisation)
    template_names = [
      :"session_#{type}_#{organisation.ods_code.downcase}",
      :"session_#{type}"
    ]

    template_names.find { GOVUK_NOTIFY_EMAIL_TEMPLATES.key?(it) }
  end
end
