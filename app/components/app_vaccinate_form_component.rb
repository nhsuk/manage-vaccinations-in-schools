# frozen_string_literal: true

class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(vaccination_record, section:, tab:)
    super

    @vaccination_record = vaccination_record
    @patient_session = vaccination_record.patient_session
    @section = section
    @tab = tab
  end

  def url
    @url ||=
      session_patient_vaccinations_path(
        @patient_session.session,
        @patient_session.patient,
        section: @section,
        tab: @tab
      )
  end

  def render?
    @patient_session.next_step == :vaccinate && @patient_session.session.today?
  end

  private

  # TODO: this code will need to be revisited in future as it only really
  # works for HPV, where we only have one vaccine. It is likely to fail for
  # the Doubles programme as that has 2 vaccines. It is also likely to fail
  # for the flu programme for the SAIS organisations that offer both nasal and
  # injectable vaccines.

  def programme
    @patient_session.programmes.first
  end

  def vaccine
    programme.vaccines.active.first
  end

  def delivery_method
    :intramuscular
  end

  def dose_sequence
    1
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
end
