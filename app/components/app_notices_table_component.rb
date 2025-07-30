# frozen_string_literal: true

class AppNoticesTableComponent < ViewComponent::Base
  def initialize(
    deceased_patients:,
    invalidated_patients:,
    restricted_patients:,
    gillick_no_notify_patients:
  )
    super

    @deceased_patients = deceased_patients
    @invalidated_patients = invalidated_patients
    @restricted_patients = restricted_patients
    @gillick_no_notify_patients = gillick_no_notify_patients
  end

  def render?
    @deceased_patients.present? || @invalidated_patients.present? ||
      @restricted_patients.present? || @gillick_no_notify_patients.present?
  end

  private

  def notices
    (
      deceased_notices + invalidated_notices + restricted_notices +
        gillick_no_notify_notices
    ).sort_by { _1[:date_time] }.reverse
  end

  def deceased_notices
    @deceased_patients.map do |patient|
      {
        patient:,
        date_time: patient.date_of_death_recorded_at,
        message: "Record updated with child’s date of death"
      }
    end
  end

  def invalidated_notices
    @invalidated_patients.map do |patient|
      {
        patient:,
        date_time: patient.invalidated_at,
        message: "Record flagged as invalid"
      }
    end
  end

  def restricted_notices
    @restricted_patients.map do |patient|
      {
        patient:,
        date_time: patient.restricted_at,
        message: "Record flagged as sensitive"
      }
    end
  end

  def gillick_no_notify_notices

    @gillick_no_notify_patients.map do |patient|
      vaccination_records = patient.vaccination_records.includes(:programme).select { it.notify_parents == false }

      {
        patient:,
        date_time:
          patient
            .vaccination_records
            .reject(&:notify_parents?)
            .max_by(&:created_at)
            &.created_at || Time.current,
        message:
          "Child gave consent for #{format_vaccinations(vaccination_records)} under Gillick competence and " \
            "does not want their parents to be notified. " \
            "These records will not be automatically synced with GP records. " \
            "Your team must let the child’s GP know they were vaccinated."
      }
    end
  end

  def format_vaccinations(vaccination_records)
    "#{vaccination_records.map(&:programme).map(&:name).to_sentence} " \
      "#{"vaccination".pluralize(vaccination_records.length)}"
  end
end
