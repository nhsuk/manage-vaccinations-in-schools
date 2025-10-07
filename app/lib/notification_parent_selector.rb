# frozen_string_literal: true

class NotificationParentSelector
  def initialize(vaccination_record:, consents: nil)
    @vaccination_record = vaccination_record

    @consents =
      if consents.present?
        consents
      else
        patient = @vaccination_record.patient

        if patient.send_notifications? && @vaccination_record.notify_parents
          patient.consents
        else
          []
        end
      end
  end

  def select_parents
    consents = select_consents

    consents
      .map do |consent|
        NotificationParentSelector.select_parents_from_consent(
          consent:,
          patient: @vaccination_record.patient
        )
      end
      .flatten
      .uniq
  end

  def self.select_parents_from_consent(consent:, patient:)
    parents = (consent.via_self_consent? ? patient.parents : [consent.parent])

    parents.select(&:contactable?)
  end

  def select_consents
    programme_id = @vaccination_record.programme_id
    academic_year = @vaccination_record.academic_year

    consents = ConsentGrouper.call(@consents, programme_id:, academic_year:)

    consents.select(&:response_provided?)
  end

  def self.select_parents(...) = new(...).select_parents
  def self.select_consents(...) = new(...).select_consents

  private_class_method :new

  private

  attr_reader :vaccination_record, :consents
end
