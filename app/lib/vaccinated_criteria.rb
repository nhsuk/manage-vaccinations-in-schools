# frozen_string_literal: true

class VaccinatedCriteria
  def initialize(patients:)
    @patients = patients
  end

  def vaccinated?(patient, programme:)
    records = vaccination_records.dig(patient.id, programme.id)
    return false if records.blank?

    # .first => outcome == already_had
    # .second => performed_at
    # .third => dose_sequence
    # .fourth => session_id

    return true if records.any? { it.first }

    if programme.menacwy?
      records.any? { patient.age(now: it.second) >= 10 }
    elsif programme.td_ipv?
      records.any? do
        (
          it.third == programme.vaccinated_dose_sequence ||
            (it.third.nil? && !it.fourth.nil?)
        ) && patient.age(now: it.second) >= 10
      end
    else
      records.any?
    end
  end

  def administered_but_not_vaccinated?(patient, programme:)
    return false if vaccinated?(patient, programme:)

    vaccination_records.dig(patient.id, programme.id).present?
  end

  private

  attr_reader :patients

  def vaccination_records
    @vaccination_records ||=
      VaccinationRecord
        .kept
        .where(patient: patients)
        .where(outcome: %w[already_had administered])
        .pluck(
          :patient_id,
          :programme_id,
          Arel.sql("outcome = ?", VaccinationRecord.outcomes[:already_had]),
          :performed_at,
          :dose_sequence,
          :session_id
        )
        .each_with_object({}) do |row, hash|
          hash[row.first] ||= {}
          hash[row.first][row.second] ||= []
          hash[row.first][row.second] << row.drop(2)
        end
  end
end
