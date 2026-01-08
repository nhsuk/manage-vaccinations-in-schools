# frozen_string_literal: true

class VaccinationNotificationCriteria
  def initialize(vaccination_record:)
    @vaccination_record = vaccination_record
  end

  def call
    return nil unless sourced_from_service?

    self_consents =
      patient
        .consents
        .via_self_consent
        .for_programme(programme)
        .where(academic_year:)
        .not_invalidated

    if self_consents.any?
      return self_consents.max_by(&:submitted_at).notify_parents_on_vaccination
    end

    true
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :vaccination_record

  delegate :patient,
           :programme,
           :sourced_from_service?,
           :academic_year,
           to: :vaccination_record
end
