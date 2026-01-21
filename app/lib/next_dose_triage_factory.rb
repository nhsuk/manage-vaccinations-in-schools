# frozen_string_literal: true

class NextDoseTriageFactory
  def initialize(vaccination_record:)
    @vaccination_record = vaccination_record
  end

  def call
    return unless should_create?

    ActiveRecord::Base.transaction do
      Triage
        .create!(attributes:)
        .tap do |next_dose_delay_triage|
          vaccination_record.update!(next_dose_delay_triage:)
        end
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :vaccination_record

  delegate :academic_year, :patient, :programme, to: :vaccination_record

  def should_create?
    return false if vaccination_record.next_dose_delay_triage_id.present?

    return false unless vaccination_record.administered? && programme.mmr?

    return false if next_date.past?

    !patient.programme_status(programme, academic_year:).vaccinated?
  end

  def next_date = vaccination_record.performed_at + 28.days

  def attributes
    {
      academic_year:,
      delay_vaccination_until: next_date,
      disease_types: [],
      notes: "Next dose #{next_date.to_fs(:long)}",
      patient:,
      programme_type: programme.type,
      status: "delay_vaccination"
    }
  end
end
