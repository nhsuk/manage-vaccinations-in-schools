# frozen_string_literal: true

class AppPatientProgrammesTableComponent < ViewComponent::Base
  def initialize(patient, programmes:)
    super

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

  CAPTION = "Vaccination programmes"
  HEADERS = ["Programme name", "Status", "Notes"].freeze

  def rows
    programmes.flat_map { |programme| rows_for_programme(programme) }
  end

  def rows_for_programme(programme)
    if programme.seasonal?
      seasonal_programme_rows(programme)
    else
      non_seasonal_programme_rows(programme)
    end
  end

  def seasonal_programme_rows(programme)
    eligible_year_groups = eligible_year_groups_for(programme:)

    AcademicYear.all.flat_map do |academic_year|
      year_group = patient.year_group(academic_year:)
      next unless year_group.in?(eligible_year_groups)

      if vaccinated_for_academic_year?(programme:, academic_year:)
        vaccination_records_for(programme).map do |vaccination_record|
          build_row(programme, academic_year, vaccination_record)
        end
      else
        [build_row(programme, academic_year)]
      end
    end
  end

  def non_seasonal_programme_rows(programme)
    academic_year = AcademicYear.pending
    vaccination_records = vaccination_records_for(programme)

    if vaccination_records.any?
      vaccination_records.map do |vaccination_record|
        build_row(programme, academic_year, vaccination_record)
      end
    else
      [build_row(programme, academic_year)]
    end
  end

  def build_row(programme, academic_year, vaccination_record = nil)
    [
      name_for_programme(programme:, academic_year:, vaccination_record:),
      status_for_programme(programme:, academic_year:, vaccination_record:),
      notes_for_programme(programme:, academic_year:, vaccination_record:)
    ]
  end

  def name_for_programme(programme:, academic_year:, vaccination_record: nil)
    name_parts = []

    name_parts << "Winter #{academic_year}" if programme.seasonal?

    if multi_dose?(vaccination_record)
      name_parts << "#{vaccination_record.dose_sequence.ordinalize} dose"
    end

    if name_parts.any?
      "#{programme.name} (#{name_parts.join(", ")})"
    else
      programme.name
    end
  end

  def multi_dose?(vaccination_record)
    vaccination_record&.dose_sequence&.> 1
  end

  def status_for_programme(programme:, academic_year:, vaccination_record: nil)
    return vaccination_status(vaccination_record) if vaccination_record

    earliest_academic_year =
      calculate_earliest_academic_year(programme:, academic_year:)

    return "—" if future_eligibility?(earliest_academic_year)

    govuk_tag(text: "No outcome", colour: "grey")
  end

  def vaccination_status(vaccination_record)
    if vaccination_record.administered?
      govuk_tag(text: "Vaccinated", colour: "green")
    else
      govuk_tag(text: "Could not vaccinate", colour: "red")
    end
  end

  def future_eligibility?(earliest_academic_year)
    earliest_academic_year&.to_academic_year_date_range&.begin&.future?
  end

  def notes_for_programme(programme:, academic_year:, vaccination_record: nil)
    return vaccination_notes(vaccination_record) if vaccination_record

    eligibility_notes(programme, academic_year)
  end

  def vaccination_notes(vaccination_record)
    if vaccination_record.administered?
      "Vaccinated #{vaccination_record.performed_at.to_date.to_fs(:long)}"
    else
      vaccination_record.outcome.humanize
    end
  end

  def eligibility_notes(programme, academic_year)
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

  def vaccinated_for_academic_year?(programme:, academic_year:)
    patient.vaccination_statuses.vaccinated.exists?(programme:, academic_year:)
  end

  def vaccination_records_for(programme)
    @vaccination_records ||= patient.vaccination_records.order(:performed_at)

    @vaccination_records.select { |record| record.programme_id == programme.id }
  end

  def eligible_year_groups_for(programme:)
    location_ids = patient.patient_sessions.joins(:session).select(:location_id)

    LocationProgrammeYearGroup
      .where(location_id: location_ids)
      .where(programme:)
      .pluck_year_groups
  end

  def calculate_earliest_academic_year(programme:, academic_year:)
    if programme.seasonal?
      academic_year
    elsif (earliest_year_group = eligible_year_groups_for(programme:).first)
      patient.birth_academic_year + earliest_year_group +
        Integer::AGE_CHILDREN_START_SCHOOL
    end
  end
end
