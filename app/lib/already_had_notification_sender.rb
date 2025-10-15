# frozen_string_literal: true

class AlreadyHadNotificationSender
  def initialize(vaccination_record:)
    @vaccination_record = vaccination_record
  end

  def call
    return if vaccination_record.sourced_from_service?
    return if would_still_be_vaccinated?

    consents = patient.consents.includes(:parent)

    consents =
      consents.where(
        "patient_already_vaccinated_notification_sent_at < ?",
        vaccination_record.created_at
      ).or(
        consents.where(
          "patient_already_vaccinated_notification_sent_at IS NULL"
        )
      )

    parents_with_consent =
      NotificationParentSelector.new(
        vaccination_record: @vaccination_record,
        consents:
      ).parents_with_consent

    parents_with_consent.each do |parent, consent|
      if parent.phone_receive_updates
        SMSDeliveryJob.perform_later(
          :vaccination_already_had,
          parent:,
          vaccination_record: @vaccination_record,
          consent:
        )
      end

      EmailDeliveryJob.perform_later(
        :vaccination_already_had,
        parent:,
        vaccination_record: @vaccination_record,
        consent:
      )

      consent.update!(
        patient_already_vaccinated_notification_sent_at: Time.current
      )
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :vaccination_record

  delegate :patient, :programme, to: :vaccination_record

  def academic_year = AcademicYear.current

  def other_vaccination_records
    patient.vaccination_records.where.not(id: vaccination_record.id)
  end

  def would_still_be_vaccinated?
    # We're not using the existing `Patient::VaccinationStatus` instance here
    # because we want to know if the patient would still be vaccinated if we
    # took away the vaccination record in question, to know whether to send
    # the notification.

    # Because we only care about whether the patient is vaccinated, and
    # although we're using the same status generator logic as elsewhere, we
    # don't need to pass  in the consents and triage as an optimisation.
    StatusGenerator::Vaccination.new(
      programme:,
      academic_year:,
      patient:,
      vaccination_records: other_vaccination_records,
      patient_locations: [],
      consents: [],
      triages: []
    ).status == :vaccinated
  end
end
