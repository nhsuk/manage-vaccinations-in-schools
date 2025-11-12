# frozen_string_literal: true

class ImportantNotices
  def initialize(patient_scope: nil, patient: nil)
    @patient_scope = patient_scope
    @patient = patient

    if patient_scope.nil? && patient.nil?
      raise "Pass either a patient_scope or a patient."
    end
  end

  def call
    notices =
      patients.flat_map do |patient|
        notices_for_patient(patient).map { it.merge(patient:) }
      end

    notices.sort_by { it[:date_time] }.reverse
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patient_scope, :patient

  def patients
    if patient
      [patient]
    else
      patient_scope_with_notices.includes(vaccination_records: :programme)
    end
  end

  def patient_scope_with_notices
    patient_scope
      .deceased
      .or(patient_scope.invalidated)
      .or(patient_scope.restricted)
      .or(patient_scope.has_vaccination_records_dont_notify_parents)
  end

  def notices_for_patient(patient)
    notices = []

    if patient.deceased?
      notices << {
        date_time: patient.date_of_death_recorded_at,
        message: "Record updated with child’s date of death"
      }
    end

    if patient.invalidated?
      notices << {
        date_time: patient.invalidated_at,
        message: "Record flagged as invalid"
      }
    end

    if patient.restricted?
      notices << {
        date_time: patient.restricted_at,
        message: "Record flagged as sensitive"
      }
    end

    no_notify_vaccination_records =
      patient.vaccination_records.select { it.notify_parents == false }
    if no_notify_vaccination_records.any?
      vaccinations_sentence =
        "#{no_notify_vaccination_records.map(&:programme).uniq.map(&:name).to_sentence} " \
          "#{"vaccination".pluralize(no_notify_vaccination_records.length)}"

      notices << {
        date_time: no_notify_vaccination_records.maximum(:performed_at),
        message:
          "Child gave consent for #{vaccinations_sentence} under Gillick competence and " \
            "does not want their parents to be notified. " \
            "These records will not be automatically synced with GP records. " \
            "Your team must let the child's GP know they were vaccinated."
      }
    end

    notices
  end
end
