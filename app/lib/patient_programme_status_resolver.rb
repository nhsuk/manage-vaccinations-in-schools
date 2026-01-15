# frozen_string_literal: true

##
# This class can be used to generate a hash suitable for use by the
# `AppAttachedTagsComponent` used to render the various statuses of any
# particular patient, programme and academic year combination.
class PatientProgrammeStatusResolver
  def initialize(
    patient,
    programme_type:,
    academic_year:,
    context_location_id: nil,
    only_if_vaccinated: false
  )
    @patient = patient
    @programme_type = programme_type
    @academic_year = academic_year
    @context_location_id = context_location_id
    @only_if_vaccinated = only_if_vaccinated
  end

  def call
    return false if only_if_vaccinated && !programme_status.vaccinated?

    { prefix:, text:, colour:, details_text: }.compact
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patient,
              :programme_type,
              :academic_year,
              :context_location_id,
              :only_if_vaccinated

  def programme_status
    @programme_status ||=
      patient.programme_status(Programme.find(programme_type), academic_year:)
  end

  def prefix = programme_status.programme.name

  def text
    if programme_status.due? && (count = programme_status.dose_sequence)
      "Due #{count.ordinalize} dose"
    else
      I18n.t(programme_status.status, scope: %i[status programme label])
    end
  end

  def colour =
    I18n.t(programme_status.status, scope: %i[status programme colour])

  def details_text
    text =
      I18n.t(
        programme_status.status,
        scope: %i[status programme details],
        default: nil
      )

    if programme_status.due?
      translation_key = programme_status.vaccine_criteria.to_param
      I18n.t(translation_key, scope: :vaccine_criteria).presence || text
    elsif programme_status.cannot_vaccinate_delay_vaccination?
      if (date = programme_status.date)
        text + " until #{date.to_fs(:long)}"
      else
        text
      end
    elsif programme_status.vaccinated_fully? ||
          programme_status.cannot_vaccinate?
      (date = programme_status.date) ? text + " on #{date.to_fs(:long)}" : text
    else
      text
    end
  end
end
