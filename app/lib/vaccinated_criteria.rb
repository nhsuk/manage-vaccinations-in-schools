# frozen_string_literal: true

class VaccinatedCriteria
  def initialize(programme, patient:, vaccination_records:)
    @programme = programme
    @patient = patient
    @vaccination_records = vaccination_records
  end

  def call
    if vaccination_records.any? { it.programme_id != programme.id }
      raise "Vaccination records provided for different programme."
    end

    return true if vaccination_records.any?(&:already_had?)

    if programme.menacwy?
      vaccination_records.any? do
        it.administered? && patient.age(now: it.performed_at) >= 10
      end
    elsif programme.td_ipv?
      vaccination_records.any? do
        it.administered? &&
          it.dose_sequence == programme.vaccinated_dose_sequence &&
          patient.age(now: it.performed_at) >= 10
      end
    else
      vaccination_records.any?(&:administered?)
    end
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :programme, :patient, :vaccination_records
end
