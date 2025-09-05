# frozen_string_literal: true

class API::Reporting::VaccinationEventsController < API::Reporting::BaseController
  # Maps between "what the column is called in the resulting CSV" and model attribute name
  CSV_HEADERS = {
    "Vaccine" => :programme_type,
    "Provider" => :team_name,
    "Local Authority" => :patient_local_authority_from_postcode_short_name,
    "Location" => :location_name,
    "Location Local Authority" => :location_local_authority_short_name,
    "Patient School" => :patient_school_name,
    "Patient School Local Authority" =>
      :patient_school_local_authority_short_name,
    "Year Group" => :patient_year_group,
    "Gender" => :patient_gender_code,
    "Month" => :event_timestamp_month,
    "Year" => :event_timestamp_year,
    "Vaccinations performed by SAIS" => :total_vaccinations_performed,
    "Patients Vaccinated" => :total_patients_vaccinated
  }.freeze

  # Maps query param names to model attribute names
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

  # Maps query param name to model attribute_name
  FILTERS = {
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
  }.freeze

  before_action :set_default_filters, :set_filters

  # GET /api/reporting/vaccination-events
  # Params:
  # - all keys in the FILTERS constant can be passed to filter the results returned
  #   e.g. academic_year=2024&team_id=1&programme=flu
  # - all keys in the GROUPS constant can be passed as group=group1,group2,... to
  #   group the results by the corresponding attribute. All results are always grouped
  #   by year and month, regardless of whether any groups were given
  #
  # Returns:
  #   Counts of each vaccination outcome, and total number of distinct patients
  #   filtered by the given filters, grouped by the given groups
  def index
    @vaccinations =
      ReportingAPI::VaccinationEvent.where(@filters.to_where_clause)
    groups = group_clause(params)
    @vaccinations = @vaccinations.group(groups).select(groups)

    # add the sums that we want to calculate
    @vaccinations =
      @vaccinations.with_counts_of_outcomes.with_count_of_patients_vaccinated

    respond_to do |format|
      format.csv do
        render_csv records: @vaccinations,
                   header_mappings: CSV_HEADERS,
                   prefix: "vaccinations"
      end
      format.any { render_paginated_json(records: @vaccinations) }
    end
  end

  private

  def group_clause(params)
    groups =
      params[:group].to_s.split(",").map { |param| GROUPS[param.strip.to_sym] }
    # we always group by year/month
    groups += %i[event_timestamp_year event_timestamp_month]
    groups.compact.uniq
  end

  # If there are no filters given in params, we default to showing the
  # current academic year
  def set_default_filters
    params[:filters] ||= AcademicYear.current
  end

  def set_filters
    @filters = ReportingAPI::EventFilter.new(params:, filters: FILTERS)
  end
end
