# frozen_string_literal: true

class NotificationParentSelector
  def initialize(vaccination_record:, consents: nil)
    @vaccination_record = vaccination_record

    @consents =
      if consents.present?
        consents
      else
        patient = @vaccination_record.patient

        if patient.send_notifications?(
             team: @vaccination_record.team,
             send_to_archived: true
           ) && @vaccination_record.notify_parents
          patient.consents
        else
          []
        end
      end
  end

  def parents_with_consent
    if (self_consent = latest_consents.find(&:via_self_consent?))
      patient
        .parents
        .select(&:contactable?)
        .map { |parent| [parent, self_consent] }
    else
      latest_consents
        .select(&:response_given?)
        .filter_map do |consent|
          parent = consent.parent
          [parent, consent] if parent&.contactable?
        end
    end
  end

  def parents = parents_with_consent.map(&:first)

  private

  attr_reader :vaccination_record, :consents

  delegate :patient, :programme_type, :academic_year, to: :vaccination_record

  def latest_consents
    @latest_consents ||=
      ConsentGrouper.call(consents, programme_type:, academic_year:)
  end
end
