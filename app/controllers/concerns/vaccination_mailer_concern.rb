# frozen_string_literal: true

module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_confirmation(vaccination_record)
    parents = parents_for_vaccination_mailer(vaccination_record)
    return if parents.empty?

    mailer_action =
      if vaccination_record.administered?
        :confirmation_administered
      else
        :confirmation_not_administered
      end

    text_template_name = :"vaccination_#{mailer_action}"

    parents.each do |parent|
      params = { parent:, vaccination_record:, sent_by: current_user }

      if parent.email.present?
        VaccinationMailer.with(params).public_send(mailer_action).deliver_later
      end

      TextDeliveryJob.perform_later(text_template_name, **params)
    end
  end

  def send_vaccination_deletion(vaccination_record)
    parents = parents_for_vaccination_mailer(vaccination_record)
    return if parents.empty?

    parents.each do |parent|
      params = { parent:, vaccination_record:, sent_by: current_user }

      if parent.email.present?
        VaccinationMailer.with(params).deleted.deliver_later
      end
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
