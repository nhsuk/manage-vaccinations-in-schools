# frozen_string_literal: true

##
# This class can be used to generate a hash suitable for use by the
# `AppAttachedTagsComponent` used to render the various statuses of any
# particular patient, programme and academic year combination.
class PatientStatusResolver
  def initialize(patient, programme:, academic_year:)
    @patient = patient
    @programme = programme
    @academic_year = academic_year
  end

  def consent
    status =
      if consent_status.given?
        value = "given"

        if programme.has_multiple_vaccine_methods?
          if triage_status.vaccine_method.present?
            value += "_#{triage_status.vaccine_method}"
          elsif (vaccine_method = consent_status.vaccine_methods.first)
            value += "_#{vaccine_method}"
          end
        end

        if triage_status.without_gelatine || consent_status.without_gelatine
          value += "_without_gelatine"
        end

        value
      else
        consent_status.status
      end

    tag_hash(status, context: :consent)
  end

  def triage
    status =
      if triage_status.safe_to_vaccinate?
        if programme.has_multiple_vaccine_methods?
          [
            "safe_to_vaccinate",
            triage_status.vaccine_method
          ].compact_blank.join("_")
        elsif triage_status.without_gelatine
          "safe_to_vaccinate_without_gelatine"
        else
          "safe_to_vaccinate"
        end
      else
        triage_status.status
      end

    tag_hash(status, context: :triage)
  end

  def vaccination
    status = vaccination_status.status
    latest_session_status = vaccination_status.latest_session_status

    details_text =
      if latest_session_status != "none_yet"
        I18n.t(latest_session_status, scope: %i[status session label])
      end

    tag_hash(status, context: :vaccination).then do |hash|
      details_text ? hash.merge(details_text:) : hash
    end
  end

  private

  attr_reader :patient, :programme, :academic_year

  def tag_hash(status, context:)
    text = I18n.t(status, scope: [:status, context, :label])
    colour = I18n.t(status, scope: [:status, context, :colour])
    { text:, colour: }
  end

  def consent_status
    @consent_status ||= patient.consent_status(programme:, academic_year:)
  end

  def triage_status
    @triage_status ||= patient.triage_status(programme:, academic_year:)
  end

  def vaccination_status
    @vaccination_status ||=
      patient.vaccination_status(programme:, academic_year:)
  end
end
