# frozen_string_literal: true

class API::Reporting::VaccinationEventsController < API::Reporting::BaseController
  CSV_HEADERS = {
    "Vaccine" => :programme_type,
    "Provider" => :team_name,
    "Local Authority" => :patient_local_authority_from_postcode_short_name,
    "Location" => :location_name,
    "Location Local Authority" => :location_local_authority_short_name,
    "Patient School" => :patient_school_name,
    "Patient School Local Authority" => :patient_school_local_authority_short_name,
    "Year Group" => :patient_year_group,
    "Gender" => :patient_gender_code,
    "Month" => :event_timestamp_month,
    "Year" => :event_timestamp_year,
    "Vaccinations performed by SAIS" => :total_vaccinations_performed,
    "Patients Vaccinated" => :total_patients_vaccinated
  }.freeze

  GROUPS = {
    local_authority: :patient_local_authority_from_postcode_short_name,
    location: :location_name,
    location_local_authority: :location_local_authority_short_name,
    school: :patient_school_name,
    school_local_authority: :patient_school_local_authority_short_name,
    year_group: :patient_year_group,
    gender: :patient_gender_code,
    programme: :programme_type,
    team: :team_name,
    organisation: :organisation_id
  }.freeze


  before_action :set_default_filters, :set_filters

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
      school_local_authority: :patient_school_local_authority_mhclg_code,
      local_authority: :patient_local_authority_from_postcode_mhclg_code,
      location_local_authority: :location_local_authority_mhclg_code,
      location_type: :location_type
    }
  end

  def group_clause(params)
    groups = params[:group].to_s.split(",").map { |param| GROUPS[param.strip.to_sym] }
    # we always group by year/month
    groups += %i[event_timestamp_year event_timestamp_month]
    groups.compact.uniq
  end
end
