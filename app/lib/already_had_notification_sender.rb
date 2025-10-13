# frozen_string_literal: true

class AlreadyHadNotificationSender
  def initialize(vaccination_record:)
    @vaccination_record = vaccination_record
  end

  def call
    return if vaccination_record.sourced_from_service?
    return if vaccinated_criteria.vaccinated?

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

  def vaccinated_criteria
    VaccinatedCriteria.new(
      programme:,
      academic_year:,
      patient:,
      vaccination_records: other_vaccination_records
    )
  end
end
