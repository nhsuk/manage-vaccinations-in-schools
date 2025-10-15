# frozen_string_literal: true

class AppPatientProgrammesTableComponent < ViewComponent::Base
  def initialize(patient, programmes:)
    @patient = patient
    @programmes = programmes
  end

  def call
    govuk_table(
      caption: CAPTION,
      head: HEADERS,
      rows:,
      first_cell_is_header: true
    )
  end

  private

  attr_reader :patient, :programmes

  delegate :govuk_table, to: :helpers

  CAPTION = "Vaccination programmes"
  HEADERS = ["Programme name", "Status", "Notes"].freeze

  def rows
    programmes.flat_map { |programme| rows_for_programme(programme:) }
  end

  def rows_for_programme(programme:)
    if programme.seasonal?
      seasonal_programme_rows(programme:)
    else
      non_seasonal_programme_rows(programme:)
    end
  end

  def seasonal_programme_rows(programme:)
    eligible_year_groups = eligible_year_groups_for(programme:)

    AcademicYear.all.flat_map do |academic_year|
      year_group = patient.year_group(academic_year:)
      next unless year_group.in?(eligible_year_groups)

      vaccination_records = vaccination_records_for(programme:, academic_year:)

      build_rows(programme:, academic_year:, vaccination_records:)
    end
  end

  def non_seasonal_programme_rows(programme:)
    academic_year = AcademicYear.pending
    vaccination_records = vaccination_records_for(programme:)

    build_rows(programme:, academic_year:, vaccination_records:)
  end

  def build_rows(programme:, academic_year:, vaccination_records:)
    if vaccination_records.any?(&:administered?)
      vaccination_records
        .select(&:administered?)
        .map do |vaccination_record|
          build_row_for_administered_record(
            programme:,
            academic_year:,
            vaccination_record:
          )
        end
    else
      [build_row_for_programme(programme:, academic_year:)]
    end
  end

  def build_row_for_programme(programme:, academic_year:)
    vaccination_status = patient.vaccination_status(programme:, academic_year:)

    [
      name_for_programme(programme:, academic_year:),
      status_for_programme(vaccination_status:, programme:, academic_year:),
      notes_for_programme(vaccination_status:, programme:, academic_year:)
    ]
  end

  def build_row_for_administered_record(
    programme:,
    academic_year:,
    vaccination_record:
  )
    [
      name_for_record(programme:, academic_year:, vaccination_record:),
      status_for_administered_record(vaccination_record:),
      notes_for_administered_record(vaccination_record:)
    ]
  end

  def name_for_programme(programme:, academic_year:)
    name_parts = []

    name_parts << "Winter #{academic_year}" if programme.seasonal?

    if name_parts.any?
      "#{programme.name} (#{name_parts.join(", ")})"
    else
      programme.name
    end
  end

  def status_for_programme(vaccination_status:, programme:, academic_year:)
    if vaccination_status.none_yet? &&
         eligibility_start_in_future?(programme:, academic_year:)
      return "-"
    end

    status = vaccination_status.status

    label = I18n.t(status, scope: %i[status vaccination label])
    colour = I18n.t(status, scope: %i[status vaccination colour])
    tag.strong(label, class: "nhsuk-tag nhsuk-tag--#{colour}")
  end

  def eligibility_start_in_future?(programme:, academic_year:)
    earliest_academic_year =
      calculate_earliest_academic_year(programme:, academic_year:)

    earliest_academic_year&.to_academic_year_date_range&.begin&.future?
  end

  def calculate_earliest_academic_year(programme:, academic_year:)
    if programme.seasonal?
      academic_year
    elsif (earliest_year_group = eligible_year_groups_for(programme:).first)
      patient.birth_academic_year + earliest_year_group +
        Integer::AGE_CHILDREN_START_SCHOOL
    end
  end

  def notes_for_programme(vaccination_status:, programme:, academic_year:)
    if vaccination_status.vaccinated?
      notes_for_status(vaccination_status:)
    elsif vaccination_status.could_not_vaccinate?
      could_not_vaccinate_notes(vaccination_status:)
    else
      no_outcome_yet_notes(vaccination_status:, programme:, academic_year:)
    end
  end

  def notes_for_status(vaccination_status:)
    latest_session_status =
      vaccination_status.latest_session_status.to_s.humanize
    date = vaccination_status.latest_date.to_fs(:long)
    "#{latest_session_status} on #{date}"
  end

  def could_not_vaccinate_notes(vaccination_status:)
    if vaccination_status.latest_session_status_had_contraindications?
      latest_triage =
        @patient
          .triages
          .includes(:performed_by)
          .order(:created_at)
          .where(created_at: vaccination_status.latest_date.all_day)
          .last

      if latest_triage
        "#{latest_triage.performed_by.full_name} decided that #{patient.full_name} could not be vaccinated"
      else
        "#{patient.full_name} could not be vaccinated"
      end
    else
      notes_for_status(vaccination_status:)
    end
  end

  def no_outcome_yet_notes(vaccination_status:, programme:, academic_year:)
    if vaccination_status.latest_session_status_none_yet?
      eligibility_notes(programme:, academic_year:)
    else
      notes_for_status(vaccination_status:)
    end
  end

  def eligibility_notes(programme:, academic_year:)
    earliest_academic_year =
      calculate_earliest_academic_year(programme:, academic_year:)

    return "—" if earliest_academic_year.nil?

    date_range = earliest_academic_year.to_academic_year_date_range
    programme_type = programme.human_enum_name(:type)
    eligibility_date = date_range.begin

    if eligibility_date.future?
      "Eligibility starts #{eligibility_date.to_fs(:long)}"
    else
      "Selected for the Year #{date_range.begin.year} to #{date_range.end.year} #{programme_type} cohort"
    end
  end

  def build_row_for_record(programme:, academic_year:, vaccination_record:)
    [
      name_for_record(vaccination_record:, programme:, academic_year:),
      status_for_record(vaccination_record:),
      notes_for_record(vaccination_record:)
    ]
  end

  def name_for_record(vaccination_record:, programme:, academic_year:)
    name_parts = []

    name_parts << "Winter #{academic_year}" if programme.seasonal?

    if multi_dose?(vaccination_record:)
      name_parts << "#{vaccination_record.dose_sequence.ordinalize} dose"
    end

    if name_parts.any?
      "#{programme.name} (#{name_parts.join(", ")})"
    else
      programme.name
    end
  end

  def multi_dose?(vaccination_record:)
    vaccination_record&.dose_sequence&.> 1
  end

  def status_for_administered_record(vaccination_record:)
    if vaccination_record.administered?
      status_for_programme(
        vaccination_status:
          Patient::VaccinationStatus.new(status: "vaccinated"),
        programme: nil,
        academic_year: nil
      )
    else
      raise "Unsupported Outcome: status_for_record should only be used for administered records"
    end
  end

  def notes_for_administered_record(vaccination_record:)
    if vaccination_record.administered?
      "Vaccinated on #{vaccination_record.performed_at.to_date.to_fs(:long)}"
    else
      raise "Unsupported Outcome: status_for_record should only be used for administered records"
    end
  end

  def vaccination_records_for(programme:, academic_year: nil)
    @vaccination_records ||= patient.vaccination_records.order(:performed_at)

    filtered_records =
      @vaccination_records.select do |record|
        record.programme_id == programme.id
      end

    if academic_year
      filtered_records.select { |record| record.academic_year == academic_year }
    else
      filtered_records
    end
  end

  def eligible_year_groups_for(programme:)
    location_ids = patient.patient_locations.select(:location_id)

    Location::ProgrammeYearGroup
      .joins(:location_year_group)
      .where(location_year_group: { location_id: location_ids })
      .where(programme:)
      .pluck_year_groups
  end
end
