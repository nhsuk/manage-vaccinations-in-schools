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
    patient = vaccination_record.patient
    return [] unless patient.send_notifications?

    patient_session =
      PatientSession.find_by(
        patient:,
        session_id: vaccination_record.session_id
      )
    return [] if patient_session.nil?

    patient_session.patient = patient

    programme = vaccination_record.programme
    consents = patient_session.latest_consents(programme:)

    parents =
      if consents.any?(&:via_self_consent?)
        consents.any?(&:notify_parents) ? patient.parents : []
      else
        consents.select(&:response_given?).filter_map(&:parent)
      end

    parents.select(&:contactable?)
  end
end
