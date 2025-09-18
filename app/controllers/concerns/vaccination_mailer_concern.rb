# frozen_string_literal: true

module VaccinationMailerConcern
  extend ActiveSupport::Concern

  def send_vaccination_confirmation(vaccination_record)
    parents = parents_for_vaccination_mailer(vaccination_record)
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

  def send_vaccination_discovered_if_required(vaccination_record)
    return if vaccination_record.sourced_from_service?
    if VaccinatedCriteria.call(
         programme: vaccination_record.programme,
         academic_year: AcademicYear.current,
         patient: vaccination_record.patient,
         vaccination_records:
           vaccination_record.patient.vaccination_records.where.not(
             id: vaccination_record.id
           )
       )
      return
    end

    consents = vaccination_record.patient.consents

    consents =
      consents.where(
        "patient_already_vaccinated_notification_sent_at < ?",
        vaccination_record.created_at
      ).or(
        consents.where(
          "patient_already_vaccinated_notification_sent_at IS NULL"
        )
      )

    consents =
      ConsentGrouper.call(
        consents,
        programme_id: vaccination_record.programme_id,
        academic_year: vaccination_record.academic_year
      )

    consents = consents.select(&:response_given?).reject(&:withdrawn_at)

    parents = consents.map(&:parent).uniq

    parents.each do |parent|
      if parent.phone_receive_updates
        SMSDeliveryJob.perform_later(
          :vaccination_discovered,
          parent:,
          vaccination_record:
        )
      end

      EmailDeliveryJob.perform_later(
        :vaccination_discovered,
        parent:,
        vaccination_record:
      )
    end

    consents.each do |consent|
      consent.update!(
        patient_already_vaccinated_notification_sent_at: Time.current
      )
    end
  end

  def parents_for_vaccination_mailer(vaccination_record)
    patient = vaccination_record.patient
    unless patient.send_notifications? && vaccination_record.notify_parents
      return []
    end

    programme_id = vaccination_record.programme_id
    academic_year = vaccination_record.academic_year

    consents =
      ConsentGrouper.call(patient.consents, programme_id:, academic_year:)

    parents =
      if consents.any?(&:via_self_consent?)
        patient.parents
      else
        consents.select(&:response_given?).filter_map(&:parent)
      end

    parents.select(&:contactable?)
  end
end
