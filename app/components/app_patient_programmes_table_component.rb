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

      AcademicYear.all.filter_map do |academic_year|
        year_group = patient.year_group(academic_year:)
        next unless year_group.in?(eligible_year_groups)

        [
          name_for_programme(programme, academic_year:),
          status_for_programme(programme, academic_year:),
          notes_for_programme(programme, academic_year:)
        ]
      end
    else
      [
        [
          name_for_programme(programme, academic_year: AcademicYear.current),
          status_for_programme(programme, academic_year: AcademicYear.current),
          notes_for_programme(programme, academic_year: AcademicYear.current)
        ]
      ]
    end
  end

  def name_for_programme(programme, academic_year:)
    if programme.seasonal?
      "#{programme.name} (Winter #{academic_year})"
    else
      programme.name
    end
  end

  def status_for_programme(programme, academic_year:)
    if vaccinated?(programme:, academic_year:)
      govuk_tag(text: "Vaccinated", colour: "green")
    else
      "—"
    end
  end

  def notes_for_programme(programme, academic_year:)
    if vaccinated?(programme:, academic_year:)
      vaccination_record =
        if programme.seasonal?
          vaccination_records(programme:)
            .select { it.academic_year == academic_year }
            .first
        else
          vaccination_records(programme:).first
        end

      return "—" if vaccination_record.nil?

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
        "Eligibility starts #{eligibility_date.to_fs(:long)}"
      else
        "Eligibility started #{eligibility_date.to_fs(:long)}"
      end
    end
  end

  def vaccinated?(programme:, academic_year:)
    patient.vaccination_statuses.vaccinated.exists?(programme:, academic_year:)
  end

  def vaccination_records(programme:)
    @vaccination_records ||=
      patient
        .vaccination_records
        .where(outcome: %w[administered already_had])
        .order(:performed_at)

    @vaccination_records.select { it.programme_id = programme.id }
  end

  def eligible_year_groups_for(programme:)
    location_ids = patient.patient_sessions.joins(:session).select(:location_id)

    Location::ProgrammeYearGroup
      .where(location_id: location_ids)
      .where(programme:)
      .pluck_year_groups
  end
end
