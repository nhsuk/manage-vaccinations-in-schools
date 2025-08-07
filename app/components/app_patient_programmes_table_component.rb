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
      eligible_year_groups = eligible_year_groups_for(programme:)
      rows = []

      AcademicYear.all.each do |academic_year|
        year_group = patient.year_group(academic_year:)
        next unless year_group.in?(eligible_year_groups)

        if vaccinated_for_academic_year?(programme:, academic_year:)
          vaccination_records(programme:).each do |vaccination_record|
            rows << [
              name_for_programme(
                programme:,
                academic_year:,
                vaccination_record:
              ),
              status_for_programme(vaccination_record:),
              notes_for_programme(
                programme:,
                academic_year:,
                vaccination_record:
              )
            ]
          end
        else
          rows << [
            name_for_programme(programme:, academic_year:),
            status_for_programme,
            notes_for_programme(programme:, academic_year:)
          ]
        end
      end

      rows
    else
      academic_year = AcademicYear.current

      rows =
        vaccination_records(programme:).map do |vaccination_record|
          [
            name_for_programme(programme:, academic_year:, vaccination_record:),
            status_for_programme(vaccination_record:),
            notes_for_programme(programme:, academic_year:, vaccination_record:)
          ]
        end

      if rows.empty?
        [
          [
            name_for_programme(programme:, academic_year:),
            status_for_programme,
            notes_for_programme(programme:, academic_year:)
          ]
        ]
      else
        rows
      end
    end
  end

  def name_for_programme(programme:, academic_year:, vaccination_record: nil)
    name_parts = []

    if vaccination_record&.dose_sequence&.> 1
      name_parts << "#{vaccination_record.dose_sequence.ordinalize} dose"
    end

    name_parts << "Winter #{academic_year}" if programme.seasonal?

    if name_parts.any?
      "#{programme.name} (#{name_parts.join(", ")})"
    else
      programme.name
    end
  end

  def status_for_programme(vaccination_record: nil)
    if vaccinated?(vaccination_record)
      govuk_tag(text: "Vaccinated", colour: "green")
    elsif vaccination_record
      govuk_tag(text: vaccination_record.outcome.humanize, colour: "grey")
    else
      "No outcome yet"
    end
  end

  def notes_for_programme(programme:, academic_year:, vaccination_record: nil)
    if vaccinated?(vaccination_record)
      "Vaccinated #{vaccination_record.performed_at.to_date.to_fs(:long)}"
    else
      earliest_academic_year =
        if programme.seasonal?
          academic_year
        elsif (earliest_year_group = eligible_year_groups_for(programme:).first)
          patient.birth_academic_year + earliest_year_group +
            Integer::AGE_CHILDREN_START_SCHOOL
        end

      return "—" if earliest_academic_year.nil?

      eligibility_date =
        earliest_academic_year.to_academic_year_date_range.begin

      if eligibility_date.future?
        "Selected for the Year (#{eligibility_date.to_fs(:long)} to 2026) HPV cohort}"
      else
        "Eligibility started #{eligibility_date.to_fs(:long)}"
      end
    end
  end

  def vaccinated?(vaccination_record)
    vaccination_record && vaccination_record.outcome == "administered"
  end

  def vaccinated_for_academic_year?(programme:, academic_year:)
    patient.vaccination_statuses.vaccinated.exists?(programme:, academic_year:)
  end

  def vaccination_records(programme:)
    @vaccination_records ||= patient.vaccination_records.order(:performed_at)

    @vaccination_records.select { it.programme_id == programme.id }
  end

  def eligible_year_groups_for(programme:)
    location_ids = patient.patient_sessions.joins(:session).select(:location_id)

    Location::ProgrammeYearGroup
      .where(location_id: location_ids)
      .where(programme:)
      .pluck_year_groups
  end

  def has_multiple_doses?(vaccination_record)
    vaccination_record.pluck(:dose_sequence).uniq.size > 1
  end
end
