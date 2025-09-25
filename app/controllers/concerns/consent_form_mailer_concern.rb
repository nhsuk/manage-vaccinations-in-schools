# frozen_string_literal: true

module ConsentFormMailerConcern
  extend ActiveSupport::Concern

  def send_consent_form_confirmation(consent_form)
    if consent_form.response_given?
      ProgrammeGrouper
        .call(consent_form.given_programmes)
        .each_value do |programmes|
          if consent_form.health_answers_require_triage?
            EmailDeliveryJob.perform_later(
              :consent_confirmation_triage,
              consent_form:,
              programmes:
            )
          elsif consent_form.session.clinic? || consent_form.session.completed?
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
        .call(consent_form.refused_programmes)
        .each_value do |programmes|
          send_consent_form_confirmation_refused(consent_form, programmes:)
        end
    else
      send_consent_form_confirmation_refused(consent_form)
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

  def send_parental_contact_warning_if_needed(patient, consent_form)
    return if patient.parents.empty?

    submitted_email = consent_form.parent_email
    submitted_phone = consent_form.parent_phone

    match_found =
      patient.parents.any? do |parent|
        email_match = parent.email.present? && submitted_email == parent.email
        phone_match = parent.phone.present? && submitted_phone == parent.phone
        email_match || phone_match
      end

    return if match_found

    patient.parents.each do |parent|
      if parent.email.present?
        EmailDeliveryJob.perform_later(
          :consent_unknown_contact_details_warning,
          consent_form:,
          parent:,
          patient:
        )
      end

      next unless parent.phone.present? && parent.phone_receive_updates
      SMSDeliveryJob.perform_later(
        :consent_unknown_contact_details_warning,
        consent_form:,
        parent:,
        patient:
      )
    end
  end
end
