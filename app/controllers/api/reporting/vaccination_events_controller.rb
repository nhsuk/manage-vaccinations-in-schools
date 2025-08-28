# frozen_string_literal: true

class API::Reporting::VaccinationEventsController < API::Reporting::BaseController
  CSV_HEADERS = {
    "Vaccine" => :programme_type,
    "Provider" => :team_name,
    "Local Authority" => :patient_local_authority_from_postcode_short_name,
    "School" => :school_name,
    "School Local Authority" => :school_local_authority_short_name,
    "Year Group" => :patient_year_group,
    "Gender" => :patient_gender_code,
    "Month" => :event_timestamp_month,
    "Year" => :event_timestamp_year,
    "Vaccinated by SAIS" => :total_vaccinated_by_sais
  }.freeze

  GROUPS = {
    local_authority: :patient_local_authority_from_postcode_short_name,
    school: :school_name,
    school_local_authority: :school_local_authority_short_name,
    year_group: :patient_year_group,
    gender: :patient_gender_code,
    programme: :programme_type,
    team: :team_name,
    organisation: :organisation_id
  }.freeze

  def index
    @vaccinations =
      ReportingAPI::VaccinationEvent.where(@filters.to_where_clause)
    groups = group_clause(params)
    @vaccinations = @vaccinations.group(groups).select(groups)

    # add the sums of various criteria
    @vaccinations =
      @vaccinations.with_counts_of_outcomes.with_count_of_patients_vaccinated

    if request.format.csv?
      render_csv records: @vaccinations,
                 header_mappings: CSV_HEADERS,
                 prefix: "vaccinations"
    else
      render_paginated_json(records: @vaccinations)
    end
  end

  private

  def filters
    # param name: attribute_name on the VaccinationEvent model
    {
      academic_year: :event_timestamp_academic_year,
      team_id: :team_id,
      organisation_id: :organisation_id,
      gender: :patient_gender_code,
      year_group: :patient_year_group,
      programme: :programme_type,
      month: :event_timestamp_month,
      year: :event_timestamp_year,
      local_authority: :patient_local_authority_from_postcode_short_name,
      school_local_authority: :school_gias_local_authority_code
    }
  end

  def group_clause(params)
    groups = params[:group].to_s.split(",").map { |param| GROUPS[param.to_sym] }
    # we always group by year/month
    groups += %i[event_timestamp_year event_timestamp_month]
    groups.uniq
  end
end
