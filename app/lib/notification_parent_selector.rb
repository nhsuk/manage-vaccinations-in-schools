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

  def call
    programme_id = @vaccination_record.programme_id
    academic_year = @vaccination_record.academic_year

    consents = ConsentGrouper.call(@consents, programme_id:, academic_year:)

    parents =
      if consents.any?(&:via_self_consent?)
        @vaccination_record.patient.parents
      else
        consents.select(&:response_provided?).filter_map(&:parent)
      end

    parents.select(&:contactable?)
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :vaccination_record, :consents
end
