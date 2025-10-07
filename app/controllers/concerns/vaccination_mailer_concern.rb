# frozen_string_literal: true

module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_confirmation(vaccination_record)
    parents = NotificationParentSelector.select_parents(vaccination_record:)
    return if parents.empty?

    template_name =
      if vaccination_record.administered?
        :vaccination_administered
      else
        :vaccination_not_administered
      end

    email_template_name =
      if vaccination_record.administered?
        :"#{template_name}_#{vaccination_record.programme.type}"
      else
        template_name
      end

    parents.each do |parent|
      params = { parent:, vaccination_record:, sent_by: try(:current_user) }

      EmailDeliveryJob.perform_later(email_template_name, **params)

      if parent.phone_receive_updates
        SMSDeliveryJob.perform_later(template_name, **params)
      end
    end
  end

  def send_vaccination_deletion(vaccination_record)
    parents = NotificationParentSelector.select_parents(vaccination_record:)
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
end
