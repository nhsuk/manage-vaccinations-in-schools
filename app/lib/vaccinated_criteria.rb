# frozen_string_literal: true

class VaccinatedCriteria
  def initialize(programme:, patient:, vaccination_records:)
    @programme = programme
    @patient = patient
    @vaccination_records = vaccination_records
  end

  def call
    vaccination_records_for_programme =
      vaccination_records.select { it.programme_id == programme.id }

    return true if vaccination_records_for_programme.any?(&:already_had?)

    administered_records =
      vaccination_records_for_programme.select(&:administered?)

    if programme.menacwy?
      administered_records.any? { patient.age(now: it.performed_at) >= 10 }
    elsif programme.td_ipv?
      administered_records.any? do
        (
          it.dose_sequence == programme.vaccinated_dose_sequence ||
            (it.dose_sequence.nil? && it.recorded_in_service?)
        ) && patient.age(now: it.performed_at) >= 10
      end
    else
      administered_records.any?
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :programme, :patient, :vaccination_records
end
