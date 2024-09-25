# frozen_string_literal: true

class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(patient_session:, section:, tab:, vaccination_record:)
    super

    @patient_session = patient_session
    @section = section
    @tab = tab
    @vaccination_record = vaccination_record
  end

  def url
    @url ||=
      session_patient_vaccinations_path(
        session_id: session.id,
        patient_id: patient.id,
        section: @section,
        tab: @tab
      )
  end

  def render?
    @patient_session.next_step == :vaccinate && session.today?
  end

  private

  def patient
    @patient_session.patient
  end

  def session
    @patient_session.session
  end

  def programme_name
    @vaccination_record.programme.name
  end

  def vaccine
    @vaccination_record.vaccine
  end

  def vaccination_common_delivery_sites
    site_options =
      vaccine.common_delivery_sites.map do |site|
        OpenStruct.new(
          value: site,
          label:
            t(
              "activerecord.attributes.vaccination_record.delivery_sites.#{site}"
            )
        )
      end

    site_options + [OpenStruct.new(value: "other", label: "Other")]
  end
end
