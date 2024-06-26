# frozen_string_literal: true

class NivsReportRow
  SITE_MAPPING = {
    "left_arm_upper_position" => "Left Upper Arm",
    "right_arm_upper_position" => "Right Upper Arm",
    "left_arm_lower_position" => "Left Upper Arm", # NIVS doesn't support lower positions
    "right_arm_lower_position" => "Right Upper Arm", # NIVS doesn't support lower positions
    "left_thigh" => "Left Thigh",
    "right_thigh" => "Right Thigh"
  }.freeze

  attr_reader :vaccination

  delegate :patient, :session, :batch, to: :vaccination

  def initialize(vaccination)
    @vaccination = vaccination
  end

  def to_a
    [
      vaccination.campaign.team.ods_code,
      session.location.urn,
      session.location.name,
      patient.nhs_number,
      patient.first_name,
      patient.last_name,
      patient.date_of_birth.to_fs(:YYYYMMDD),
      "Not Known", # gender code not available
      patient.address_postcode,
      vaccination.recorded_at.to_date.to_fs(:YYYYMMDD),
      batch.vaccine.brand,
      batch.name,
      batch.expiry.to_fs(:YYYYMMDD),
      delivery_site,
      "1", # dose sequence hard-coded to 1 for HPV
      "MAVIS-#{patient.id}",
      "", # LOCAL_PATIENT_ID_URI
      "1 - School"
    ]
  end

  def delivery_site
    return "Nasal" if batch.vaccine.nasal?

    SITE_MAPPING[vaccination.delivery_site]
  end
end
