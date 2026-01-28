# frozen_string_literal: true

class Reports::CareplusExporter
  def initialize(team:, programme:, academic_year:, start_date:, end_date:)
    @team = team
    @programme = programme
    @academic_year = academic_year
    @start_date = start_date
    @end_date = end_date
  end

  def call
    CSV.generate(headers:, write_headers: true) do |csv|
      vaccination_records
        .group_by(&:patient)
        .transform_values(&:reverse)
        .each do |patient, vaccination_records|
          rows(patient:, vaccination_records:).each { |row| csv << row }
        end
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :team, :programme, :academic_year, :start_date, :end_date

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
      "Vaccine Code #{number}",
      "Dose #{number}",
      "Reason Not Given #{number}",
      "Site #{number}",
      "Manufacturer #{number}",
      "Batch No #{number}"
    ]
  end

  def vaccination_records
    scope =
      VaccinationRecord
        .kept
        .for_programme(programme)
        .where(team_location: { team_id: team.id })
        .for_academic_year(academic_year)
        .administered
        .order_by_performed_at
        .includes(
          :batch,
          :patient,
          :vaccine,
          session: %i[location team_location]
        )

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

  def consents
    @consents ||=
      Consent
        .select("DISTINCT ON (patient_id) consents.*")
        .for_programme(programme)
        .where(patient: vaccination_records.select(:patient_id), academic_year:)
        .not_invalidated
        .response_given
        .order(:patient_id, created_at: :desc)
        .includes(:parent, :patient)
        .group_by(&:patient_id)
        .transform_values(&:first)
  end

  def rows(patient:, vaccination_records:)
    vaccination_records
      .group_by(&:session)
      .flat_map do |session, records_in_same_session|
        records_in_same_session
          .group_by { it.performed_at.to_date }
          .map do |date, records|
            [
              patient.nhs_number,
              patient.family_name,
              patient.given_name,
              patient.date_of_birth.strftime("%d/%m/%Y"),
              patient.restricted? ? "" : patient.address_line_1,
              consents[patient.id]&.name || "",
              99, # Ethnicity, 99 is "Not known"
              date.strftime("%d/%m/%Y"),
              records.first.performed_at.strftime("%H:%M"),
              session.location.school? ? "SC" : "CL", # Venue Type
              session.location.dfe_number || team.careplus_venue_code, # Venue Code
              team.careplus_staff_type,
              team.careplus_staff_code,
              "Y", # Attended; Did not attends do not get recorded on GP systems
              "", # Reason Not Attended; Always blank
              "", # Suspension End Date; Doesn't need to be used
              *vaccine_fields(records, 0),
              *vaccine_fields(records, 1),
              *vaccine_fields(records, 2),
              *vaccine_fields(records, 3),
              *vaccine_fields(records, 4)
            ]
          end
      end
  end

  def blank_vaccine_fields
    ["", "", "", "", "", ""]
  end

  def vaccine_fields(vaccination_records, index)
    record = vaccination_records[index]
    return blank_vaccine_fields unless record

    [
      record.vaccine.snomed_product_code, # Vaccine X
      vaccine_code(record), # Code X field
      record.dose_sequence.present? ? "#{record.dose_sequence}P" : "", # Dose X field
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

  def vaccine_code(vaccination_record)
    programme = vaccination_record.programme

    if programme.flu? && vaccination_record.delivery_method_nasal_spray?
      "FLUENZ"
    elsif programme.flu?
      "FLU"
    elsif programme.hpv?
      "HPV"
    elsif programme.menacwy?
      "ACWYX14"
    elsif programme.mmr?
      programme.mmrv_variant? ? "MMRV" : "MMR"
    elsif programme.td_ipv?
      "3IN1"
    else
      raise "Unknown programme: #{programme.type}"
    end
  end
end
