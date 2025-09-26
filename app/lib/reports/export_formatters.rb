# frozen_string_literal: true

module Reports::ExportFormatters
  extend ActiveSupport::Concern

  def school_urn(location:, patient:)
    if location&.school?
      location.urn
    elsif patient.home_educated?
      "999999"
    elsif (school = patient.school)
      school.urn
    else
      "888888"
    end
  end

  def school_name(location:, patient:)
    location&.school? ? location.name : patient.school&.name || ""
  end

  def care_setting(location:)
    location&.school? ? "1" : "2"
  end

  def clinic_name(location:, vaccination_record:)
    location&.school? ? "" : vaccination_record.location_name
  end

  def consent_status(patient:, programme:, academic_year:)
    consent_status = patient.consent_status(programme:, academic_year:)
    if consent_status.given?
      if programme.has_multiple_vaccine_methods?
        vaccine_methods =
          consent_status.vaccine_methods.map do |method|
            Vaccine.human_enum_name(:method, method).downcase
          end
        "Consent given for #{vaccine_methods.to_sentence}"
      else
        "Consent given"
      end
    elsif consent_status.refused?
      "Consent refused"
    elsif consent_status.conflicts?
      "Conflicting consent"
    else
      ""
    end
  end

  def consent_details(consents:)
    values =
      consents
        .sort_by(&:created_at)
        .reverse
        .map do |consent|
          "On #{consent.created_at.to_date} at #{consent.created_at.strftime("%H:%M")} " \
            "#{consent.response.humanize.upcase} by #{consent.name}"
        end

    values.join(", ")
  end

  def health_question_answers(consents:)
    health_answers = ConsolidatedHealthAnswers.new(consents).to_h

    values =
      health_answers.map do |question, responses|
        formatted_responses =
          responses.map do
            str = "#{_1[:answer]} from #{_1[:responder]}"
            str += " (#{_1[:notes]})" if _1[:notes].present?
            str
          end

        "#{question} #{formatted_responses.join(", ")}"
      end

    values.join("\r\n")
  end

  def gillick_status(gillick_assessment:)
    return "" if gillick_assessment.nil?

    if gillick_assessment.gillick_competent?
      "Gillick competent"
    else
      "Not Gillick competent"
    end
  end

  def psd_status(patient_specific_direction:)
    patient_specific_direction ? "PSD added" : ""
  end

  def vaccinated(vaccination_record:)
    vaccination_record.administered? ? "Y" : "N"
  end

  def anatomical_site(vaccination_record:)
    if vaccination_record.delivery_site
      ImmunisationImportRow::DELIVERY_SITES.key(
        vaccination_record.delivery_site
      )
    else
      ""
    end
  end

  def route_of_vaccination(vaccination_record:)
    vaccination_record.delivery_method || ""
  end

  def dose_sequence(vaccination_record:)
    vaccination_record.administered? ? vaccination_record.dose_sequence : ""
  end

  def reason_not_vaccinated(vaccination_record:)
    if vaccination_record.administered?
      ""
    else
      ImmunisationImportRow::REASONS_NOT_ADMINISTERED.key(
        vaccination_record.outcome.to_sym
      )
    end
  end
end
