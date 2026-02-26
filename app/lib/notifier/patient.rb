# frozen_string_literal: true

class Notifier::Patient
  extend ActiveSupport::Concern

  def initialize(patient)
    @patient = patient
  end

  def send_clinic_invitation(programme_types:, team:, academic_year:, sent_by:)
    return unless send_notification?(team:)

    programme_types.reject! do |programme_type|
      patient.programme_status(
        Programme.find(programme_type),
        academic_year:
      ).vaccinated_fully?
    end

    return if programme_types.empty?

    already_sent =
      patient.clinic_notifications.any? do
        it.team_id == team.id && it.academic_year == academic_year &&
          (programme_types - it.programme_types).empty? # is subset
      end

    type = already_sent ? :subsequent_invitation : :initial_invitation

    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    ClinicNotification.create!(
      patient:,
      programme_types:,
      team:,
      academic_year:,
      type:,
      sent_at: Time.current,
      sent_by:
    )

    template_name = determine_template_name(type, team:)

    params = { academic_year:, patient:, programme_types:, sent_by:, team: }

    parents.each do |parent|
      EmailDeliveryJob.perform_later(template_name, parent:, **params)
      SMSDeliveryJob.perform_later(template_name, parent:, **params)
    end
  end

  private

  attr_reader :patient

  def send_notification?(team:)
    patient.send_notifications?(team:, send_to_archived: true) &&
      parents.present?
  end

  def parents
    @parents ||= patient.parents.select(&:contactable?).uniq
  end

  def determine_template_name(type, team:)
    template_names = [
      :"clinic_#{type}_#{team.organisation.ods_code.downcase}",
      :"clinic_#{type}"
    ]

    template_names.find { GOVUK_NOTIFY_EMAIL_TEMPLATES.key?(it) }
  end
end
