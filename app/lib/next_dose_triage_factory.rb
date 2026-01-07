# frozen_string_literal: true

class NextDoseTriageFactory
  def initialize(vaccination_record:, current_user:)
    @vaccination_record = vaccination_record
    @current_user = current_user
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

  attr_reader :vaccination_record, :current_user

  delegate :academic_year, :patient, :programme, to: :vaccination_record

  def should_create?
    unless vaccination_record.recorded_in_service? &&
             vaccination_record.administered? && programme.mmr?
      return false
    end

    dose_sequence =
      patient.vaccination_status(programme:, academic_year:).dose_sequence

    dose_sequence != programme.maximum_dose_sequence
  end

  def team = current_user.selected_team

  def next_date = vaccination_record.performed_at + 28.days

  def attributes
    {
      patient:,
      team:,
      programme:,
      performed_by: current_user,
      status: "delay_vaccination",
      academic_year:,
      notes: "Next dose #{next_date.to_fs(:long)}",
      delay_vaccination_until: next_date
    }
  end
end
