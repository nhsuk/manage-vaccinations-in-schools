# frozen_string_literal: true

module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_confirmation(vaccination_record)
    parents = parents_for_vaccination_mailer(vaccination_record)
    return if parents.empty?

    template_name =
      if vaccination_record.administered?
        :vaccination_confirmation_administered
      else
        :vaccination_confirmation_not_administered
      end

    parents.each do |parent|
      params = { parent:, vaccination_record:, sent_by: try(:current_user) }

      EmailDeliveryJob.perform_later(template_name, **params)

      if parent.phone_receive_updates
        SMSDeliveryJob.perform_later(template_name, **params)
      end
    end
  end

  def send_vaccination_deletion(vaccination_record)
    parents = parents_for_vaccination_mailer(vaccination_record)
    return if parents.empty?

    sent_by = try(:current_user)

    parents.each do |parent|
      EmailDeliveryJob.perform_later(
        :vaccination_deleted,
        parent:,
        vaccination_record:,
        sent_by:
      )
    end
  end

  def parents_for_vaccination_mailer(vaccination_record)
    patient_session = vaccination_record.patient_session
    patient = patient_session.patient

    return [] unless patient.send_notifications?

    consents = patient_session.latest_consents

    parents =
      if consents.any?(&:via_self_consent?)
        consents.any?(&:notify_parents) ? patient.parents : []
      else
        consents.select(&:response_given?).filter_map(&:parent)
      end

    parents.select(&:contactable?)
  end
end
