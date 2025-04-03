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

  def consent_status(patient:, programme:)
    case patient.consent_outcome.status[programme]
    when Patient::ConsentOutcome::GIVEN
      "Consent given"
    when Patient::ConsentOutcome::REFUSED
      "Consent refused"
    when Patient::ConsentOutcome::CONFLICTS
      "Conflicting consent"
    else
      ""
    end
  end

  def consent_details(consents:)
    values =
      consents.map do |consent|
        "#{consent.response.humanize} by #{consent.name} at #{consent.created_at}"
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

  def vaccinated(vaccination_record:)
    vaccination_record.administered? ? "Y" : "N"
  end

  def anatomical_site(vaccination_record:)
    if vaccination_record.delivery_site
      ImmunisationImport::RowParser::DELIVERY_SITES.key(
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
      ImmunisationImport::RowParser::REASONS_NOT_VACCINATED.key(
        vaccination_record.outcome.to_sym
      )
    end
  end
end
