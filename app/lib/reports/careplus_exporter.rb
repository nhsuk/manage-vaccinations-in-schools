# frozen_string_literal: true

class Reports::CareplusExporter
  def initialize(organisation:, programme:, start_date:, end_date:)
    @organisation = organisation
    @programme = programme
    @start_date = start_date
    @end_date = end_date
  end

  def call
    CSV.generate(headers:, write_headers: true) do |csv|
      programme
        .sessions
        .where(organisation:)
        .find_each do |session|
          patient_sessions_for_session(session).each do |patient_session|
            rows(patient_session:).each { |row| csv << row }
          end
        end
    end
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :organisation, :programme, :start_date, :end_date

  def headers
    [
      "NHS Number",
      "Surname",
      "Forename",
      "Date of Birth",
      "Address Line 1",
      "Person Giving Consent",
      "Ethnicity",
      "Date Attended",
      "Time Attended",
      "Venue Type",
      "Venue Code",
      "Staff Type",
      "Staff Code",
      "Attended",
      "Reason Not Attended",
      "Suspension End Date",
      *vaccine_columns(1),
      *vaccine_columns(2),
      *vaccine_columns(3),
      *vaccine_columns(4),
      *vaccine_columns(5)
    ]
  end

  def vaccine_columns(number)
    [
      "Vaccine #{number}",
      "Dose #{number}",
      "Reason Not Given #{number}",
      "Site #{number}",
      "Manufacturer #{number}",
      "Batch No #{number}"
    ]
  end

  def patient_sessions_for_session(session)
    scope =
      session
        .patient_sessions
        .includes(
          :location,
          :programmes,
          patient: [
            :school,
            :vaccination_records,
            { consents: %i[parent patient] }
          ]
        )
        .where.not(vaccination_records: { id: nil })
        .merge(VaccinationRecord.administered)

    if start_date.present?
      scope =
        scope.where(
          "vaccination_records.created_at >= ?",
          start_date.beginning_of_day
        ).or(
          scope.where(
            "vaccination_records.updated_at >= ?",
            start_date.beginning_of_day
          )
        )
    end

    if end_date.present?
      scope =
        scope.where(
          "vaccination_records.created_at <= ?",
          end_date.end_of_day
        ).or(
          scope.where(
            "vaccination_records.updated_at <= ?",
            end_date.end_of_day
          )
        )
    end

    scope
  end

  def rows(patient_session:)
    patient = patient_session.patient

    patient_session.programmes.filter_map do |programme|
      vaccination_records =
        patient_session.vaccination_records(
          programme:,
          for_session: true
        ).select(&:administered?)

      if vaccination_records.any?
        existing_row(patient:, patient_session:, vaccination_records:)
      end
    end
  end

  def existing_row(patient:, patient_session:, vaccination_records:)
    first_vaccination = vaccination_records.first
    programme = first_vaccination.programme

    [
      patient.nhs_number,
      patient.family_name,
      patient.given_name,
      patient.date_of_birth.strftime("%d/%m/%Y"),
      patient.address_line_1,
      patient_session.latest_consents(programme:).first&.name || "",
      99, # Ethnicity, 99 is "Not known"
      first_vaccination.performed_at.strftime("%d/%m/%Y"),
      first_vaccination.performed_at.strftime("%H:%M"),
      patient_session.location.school? ? "SC" : "CL", # Venue Type
      patient_session.location.dfe_number || organisation.careplus_venue_code, # Venue Code
      "IN", # Staff Type
      "LW5PM", # Staff Code
      "Y", # Attended; Did not attends do not get recorded on GP systems
      "", # Reason Not Attended; Always blank
      "", # Suspension End Date; Doesn't need to be used
      *vaccine_fields(vaccination_records, 0),
      *vaccine_fields(vaccination_records, 1),
      *vaccine_fields(vaccination_records, 2),
      *vaccine_fields(vaccination_records, 3),
      *vaccine_fields(vaccination_records, 4)
    ]
  end

  def blank_vaccine_fields
    ["", "", "", "", "", ""]
  end

  def vaccine_fields(vaccination_records, index)
    record = vaccination_records[index]
    return blank_vaccine_fields unless record

    [
      record.vaccine.snomed_product_code, # Vaccine X
      "#{record.dose_sequence}P", # Dose X field
      "", # Reason Not Given X
      coded_site(record.delivery_site), # Site X; Coded value
      record.vaccine.manufacturer, # Manufacturer X
      record.batch.name # Batch No X
    ]
  end

  # Official list of Careplus codes
  # AB: Abdomen
  # ALT: Anterolateral Thigh
  # L: Left
  # LA: Left Arm
  # LALT: Left Upper Anterolateral Thigh
  # LB: Left Buttock
  # LL: Left Leg
  # LLIF: Left Lower Inside Forearm
  # LT: Left Thigh
  # MOU: Mouth
  # N: Nasal
  # NA: Not Applicable
  # NK: Not Known
  # O: Other
  # R: Right
  # RA: Right Arm
  # RALT: Right Upper Anterolateral Thigh
  # RB: Right Buttock
  # RL: Right Leg
  # RLIF: Right Lower Inside Forearm
  # RT: Right Thigh
  # U: Unconfirmed
  # UA: Upper Arm
  # ULA: Upper Left Arm
  # URA: Upper Right Arm
  def coded_site(site)
    {
      left_arm_upper_position: "ULA",
      left_arm_lower_position: "LLIF",
      right_arm_upper_position: "URA",
      right_arm_lower_position: "RLIF",
      left_thigh: "LT",
      right_thigh: "RT",
      left_buttock: "LB",
      right_buttock: "RB",
      nose: "N"
      # We don't implement the other codes currently
    }.fetch(site.to_sym)
  end
end
