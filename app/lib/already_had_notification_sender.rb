# frozen_string_literal: true

class AlreadyHadNotificationSender
  def initialize(vaccination_record:)
    @vaccination_record = vaccination_record
  end

  def call
    return if @vaccination_record.sourced_from_service?
    if VaccinatedCriteria.call(
         programme: @vaccination_record.programme,
         academic_year: AcademicYear.current,
         patient: @vaccination_record.patient,
         vaccination_records:
           @vaccination_record.patient.vaccination_records.where.not(
             id: @vaccination_record.id
           )
       )
      return
    end

    consents = @vaccination_record.patient.consents.includes(:parent)
    consents =
      consents.where(
        "patient_already_vaccinated_notification_sent_at < ?",
        @vaccination_record.created_at
      ).or(
        consents.where(
          "patient_already_vaccinated_notification_sent_at IS NULL"
        )
      )
    consents = consents.select(&:response_given?).reject(&:withdrawn?)

    consents =
      NotificationParentSelector.select_consents(
        vaccination_record: @vaccination_record,
        consents:
      )

    consents.each do |consent|
      parents =
        NotificationParentSelector.select_parents_from_consent(
          consent:,
          patient: @vaccination_record.patient
        )

      parents.each do |parent|
        if parent.phone_receive_updates
          SMSDeliveryJob.perform_later(
            :vaccination_discovered,
            parent:,
            vaccination_record: @vaccination_record,
            consent:
          )
        end

        EmailDeliveryJob.perform_later(
          :vaccination_discovered,
          parent:,
          vaccination_record: @vaccination_record,
          consent:
        )
      end

      consent.update!(
        patient_already_vaccinated_notification_sent_at: Time.current
      )
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :vaccination_record
end
