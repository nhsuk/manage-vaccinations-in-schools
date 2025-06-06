# frozen_string_literal: true

module ConsentFormMailerConcern
  extend ActiveSupport::Concern

  def send_consent_form_confirmation(consent_form)
    if consent_form.consent_refused?
      send_consent_form_confirmation_refused(consent_form)
    else
      ProgrammeGrouper
        .call(consent_form.chosen_programmes)
        .each_value do |programmes|
          if consent_form.needs_triage?
            EmailDeliveryJob.perform_later(
              :consent_confirmation_triage,
              consent_form:,
              programmes:
            )
          elsif consent_form.actual_session.clinic? ||
                consent_form.actual_session.completed?
            EmailDeliveryJob.perform_later(
              :consent_confirmation_clinic,
              consent_form:,
              programmes:
            )
          else
            EmailDeliveryJob.perform_later(
              :consent_confirmation_given,
              consent_form:,
              programmes:
            )

            if consent_form.parent_phone_receive_updates
              SMSDeliveryJob.perform_later(
                :consent_confirmation_given,
                consent_form:,
                programmes:
              )
            end
          end
        end

      ProgrammeGrouper
        .call(consent_form.not_chosen_programmes)
        .each_value do |programmes|
          send_consent_form_confirmation_refused(consent_form, programmes:)
        end
    end
  end

  def send_consent_form_confirmation_refused(consent_form, programmes: nil)
    params = { consent_form: }
    params[:programmes] = programmes if programmes

    EmailDeliveryJob.perform_later(:consent_confirmation_refused, **params)

    if consent_form.parent_phone_receive_updates
      SMSDeliveryJob.perform_later(:consent_confirmation_refused, **params)
    end
  end
end
