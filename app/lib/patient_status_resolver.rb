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
    if vaccination_status.vaccinated?
      details_text =
        if vaccination_status.latest_session_status_already_had?
          "Already had the vaccine"
        else
          "Vaccinated on #{vaccination_status.latest_date.to_fs(:long)}"
        end

      tag_hash("vaccinated", context: :vaccination).merge(details_text:)
    elsif vaccination_status.not_eligible?
      tag_hash("not_eligible", context: :vaccination)
    else
      details_text =
        if triage_status.do_not_vaccinate?
          "Contraindicated"
        elsif triage_status.delay_vaccination?
          "Delay vaccination"
        elsif consent_status.refused?
          "Consent refused"
        elsif consent_status.conflicts?
          "Conflicting consent"
        elsif !vaccination_status.latest_session_status.nil?
          status_string =
            if vaccination_status.latest_session_status_refused?
              "Child refused"
            elsif vaccination_status.latest_session_status_absent?
              "Absent"
            elsif vaccination_status.latest_session_status_unwell?
              "Unwell"
            elsif vaccination_status.latest_session_status_contraindicated?
              "Contraindicated"
            end
          "#{status_string} on #{vaccination_status.latest_date.to_fs(:long)}"
        elsif triage_status.safe_to_vaccinate?
          triage.fetch(:text)
        else
          consent.fetch(:text)
        end

      status = vaccination_status.status
      text = I18n.t(status, scope: %i[status vaccination label])

      if (count = vaccination_status.dose_sequence)
        text =
          if vaccination_status.eligible?
            "Eligible for #{count.ordinalize} dose"
          elsif vaccination_status.due?
            "Due #{count.ordinalize} dose"
          end
      end

      colour = I18n.t(status, scope: %i[status vaccination colour])

      { text:, colour:, details_text: }
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
