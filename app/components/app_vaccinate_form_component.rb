# frozen_string_literal: true

class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(patient_session:, programme:, vaccinate_form:)
    super

    @patient_session = patient_session
    @programme = programme
    @vaccinate_form = vaccinate_form || default_vaccinate_form
  end

  private

  attr_reader :patient_session, :programme, :vaccinate_form

  delegate :patient, :session, to: :patient_session

  def url
    session_patient_programme_vaccinations_path(session, patient, programme)
  end

  # TODO: this code will need to be revisited in future as it only really
  # works for HPV, where we only have one vaccine. It is likely to fail for
  # the flu programme for the SAIS organisations that offer both nasal and
  # injectable vaccines.

  def vaccine
    programme.vaccines.active.first
  end

  def delivery_method
    :intramuscular
  end

  def dose_sequence
    programme.default_dose_sequence
  end

  def common_delivery_sites_options
    options =
      vaccine.common_delivery_sites.map do |site|
        OpenStruct.new(
          value: site,
          label:
            t(
              site,
              scope: "activerecord.attributes.vaccination_record.delivery_sites"
            )
        )
      end

    options + [OpenStruct.new(value: "other", label: "Other")]
  end

  def default_vaccinate_form
    pre_screening = patient_session.pre_screenings.last

    VaccinateForm.new(
      feeling_well: pre_screening&.feeling_well,
      knows_vaccination: pre_screening&.knows_vaccination,
      no_allergies: pre_screening&.no_allergies,
      not_already_had: pre_screening&.not_already_had,
      not_pregnant: pre_screening&.not_pregnant,
      not_taking_medication: pre_screening&.not_taking_medication,
      pre_screening_notes: pre_screening&.notes || ""
    )
  end
end
