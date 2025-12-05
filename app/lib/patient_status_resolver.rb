# frozen_string_literal: true

##
# This class can be used to generate a hash suitable for use by the
# `AppAttachedTagsComponent` used to render the various statuses of any
# particular patient, programme and academic year combination.
class PatientStatusResolver
  def initialize(patient, programme:, academic_year:, context_location_id: nil)
    @patient = patient
    @programme = programme
    @academic_year = academic_year
    @context_location_id = context_location_id
  end

  def consent
    status =
      if consent_status.given?
        vaccine_method =
          triage_status.vaccine_method.presence ||
            consent_status.vaccine_methods.first

        without_gelatine =
          triage_status.without_gelatine || consent_status.without_gelatine

        parts = [
          "given",
          vaccine_method,
          without_gelatine ? "without_gelatine" : nil,
          without_gelatine && @programme.flu? ? "flu" : nil
        ]

        parts.compact_blank.join("_")
      else
        consent_status.status
      end

    tag_hash(status, context: :consent)
  end

  def programme
    hash = tag_hash(programme_status.status, context: :programme)

    if programme_status.due?
      if (count = programme_status.dose_sequence)
        hash[:text] = "Due #{count.ordinalize} dose"
      end

      translation_key = programme_status.vaccine_criteria.to_param

      if (
           details_text = I18n.t(translation_key, scope: :vaccine_criteria)
         ).present?
        hash[:details_text] = details_text
      end
    elsif programme_status.cannot_vaccinate_delay_vaccination?
      if (date = programme_status.date)
        hash[:details_text] += " until #{date.to_fs(:long)}"
      end
    elsif programme_status.vaccinated_fully? ||
          programme_status.cannot_vaccinate?
      if (date = programme_status.date)
        hash[:details_text] += " on #{date.to_fs(:long)}"
      end
    end

    hash
  end

  def triage
    status =
      if triage_status.safe_to_vaccinate?
        vaccine_method = triage_status.vaccine_method
        without_gelatine = triage_status.without_gelatine

        parts = [
          "safe_to_vaccinate",
          vaccine_method,
          without_gelatine ? "without_gelatine" : nil,
          without_gelatine && @programme.flu? ? "flu" : nil
        ]

        parts.compact_blank.join("_")
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
        elsif context_location_id.nil? ||
              vaccination_status.latest_location_id.nil? ||
              vaccination_status.latest_location_id == context_location_id
          "Vaccinated on #{vaccination_status.latest_date.to_fs(:long)}"
        else
          "Vaccinated at #{vaccination_status.latest_location.name}"
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

  attr_reader :patient, :academic_year, :context_location_id

  def tag_hash(status, context:)
    text = I18n.t(status, scope: [:status, context, :label])
    colour = I18n.t(status, scope: [:status, context, :colour])
    details_text =
      I18n.t(status, scope: [:status, context, :details], default: nil)
    { text:, colour:, details_text: }.compact
  end

  def consent_status
    @consent_status ||=
      patient.consent_status(programme: @programme, academic_year:)
  end

  def programme_status
    @programme_status ||= patient.programme_status(@programme, academic_year:)
  end

  def triage_status
    @triage_status ||=
      patient.triage_status(programme: @programme, academic_year:)
  end

  def vaccination_status
    @vaccination_status ||=
      patient.vaccination_status(programme: @programme, academic_year:)
  end
end
