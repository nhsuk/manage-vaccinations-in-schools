# frozen_string_literal: true

module Reports::ExportFormatters
  extend ActiveSupport::Concern

  def school_urn(location:, patient:)
    if location.school?
      location.urn
    elsif patient.home_educated?
      "999999"
    else
      patient.school&.urn || "888888"
    end
  end

  def school_name(location:, patient:)
    location.school? ? location.name : patient.school&.name || ""
  end

  def care_setting(location:)
    location.school? ? "1" : "2"
  end

  def clinic_name(location:, vaccination_record:)
    location.school? ? "" : vaccination_record.location_name
  end

  def consent_details(consents:)
    values =
      consents.map do |consent|
        "#{consent.response.humanize} by #{consent.name} at #{consent.recorded_at}"
      end

    values.join(", ")
  end

  def health_question_answers(consents:)
    values =
      consents.flat_map do |consent|
        consent.health_answers.map do |health_answer|
          "#{health_answer.question} - #{health_answer.response}"
        end
      end

    values.join(", ")
  end

  def gillick_status(gillick_assessment:)
    return "" if gillick_assessment.nil?

    if gillick_assessment.gillick_competent?
      "Gillick competent"
    else
      "Not Gillick competent"
    end
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
    if vaccination_record.delivery_site_nose?
      "nasal_spray"
    elsif vaccination_record.delivery_site.present?
      "intramuscular"
    else
      ""
    end
  end

  def dose_sequence(vaccination_record:)
    vaccination_record.administered? ? vaccination_record.dose_sequence : ""
  end

  def reason_not_vaccinated(vaccination_record:)
    if vaccination_record.reason.present?
      ImmunisationImportRow::REASONS.key(vaccination_record.reason.to_sym)
    else
      ""
    end
  end
end
