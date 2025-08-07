# frozen_string_literal: true

module PatientsHelper
  # Replace each space in NHS number with a non-breaking space and
  # zero-width word joiner to prevent telephone format detection
  def patient_nhs_number(patient)
    span =
      if patient.nhs_number.blank?
        "Not provided"
      else
        tag.span(class: %w[app-u-monospace nhsuk-u-nowrap]) do
          patient
            .nhs_number
            .to_s
            .gsub(/(\d{3})(\d{3})(\d{4})/, "\\1 \\2 \\3")
            .html_safe
        end
      end

    patient.try(:invalidated?) ? tag.s(span) : span
  end

  def patient_date_of_birth(patient)
    "#{patient.date_of_birth.to_fs(:long)} (aged #{patient.age})"
  end

  def patient_school(patient)
    if (school = patient.school).present?
      school.name
    elsif patient.home_educated
      "Home-schooled"
    else
      "Unknown school"
    end
  end

  def patient_year_group(patient, academic_year:)
    parts = [
      format_year_group(patient.year_group(academic_year:)),
      if patient.registration_academic_year == academic_year &&
           patient.registration.present?
        "(#{patient.registration})"
      end,
      if academic_year != AcademicYear.current
        "(#{format_academic_year(academic_year)} academic year)"
      end
    ]

    parts.compact.join(" ")
  end

  def patient_parents(patient)
    format_parents_with_relationships(patient.parent_relationships)
  end

  def patient_important_notices(patient)
    notifications = []

    if patient.deceased?
      notifications << {
        date_time: patient.date_of_death_recorded_at,
        message: "Record updated with child’s date of death"
      }
    end

    if patient.invalidated?
      notifications << {
        date_time: patient.invalidated_at,
        message: "Record flagged as invalid"
      }
    end

    if patient.restricted?
      notifications << {
        date_time: patient.restricted_at,
        message: "Record flagged as sensitive"
      }
    end

    no_notify_vaccination_records =
      patient.vaccination_records.select { it.notify_parents == false }
    if no_notify_vaccination_records.any?
      notifications << {
        date_time: no_notify_vaccination_records.maximum(:performed_at),
        message:
          "Child gave consent for #{format_vaccinations(no_notify_vaccination_records)} under Gillick competence and " \
            "does not want their parents to be notified. " \
            "These records will not be automatically synced with GP records. " \
            "Your team must let the child's GP know they were vaccinated."
      }
    end

    notifications.sort_by { |notification| notification[:date_time] }.reverse
  end

  private

  def format_vaccinations(vaccination_records)
    "#{vaccination_records.map(&:programme).map(&:name).to_sentence} " \
      "#{"vaccination".pluralize(vaccination_records.length)}"
  end
end
