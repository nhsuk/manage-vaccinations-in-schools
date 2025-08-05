# frozen_string_literal: true

class VaccinationNotificationCriteria
  def initialize(vaccination_record:)
    @vaccination_record = vaccination_record
  end

  def call
    patient
      .consents
      .where(programme:)
      .not_invalidated
      .not_withdrawn
      .none? { it.notify_parents_on_vaccination == false }
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :vaccination_record

  delegate :patient, :programme, to: :vaccination_record
end
