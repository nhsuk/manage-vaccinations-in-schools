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

  def programme(only_if_vaccinated: false)
    return if only_if_vaccinated && !programme_status.vaccinated?

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

    hash.merge(prefix: programme_status.programme.name)
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

  def programme_status
    @programme_status ||= patient.programme_status(@programme, academic_year:)
  end
end
