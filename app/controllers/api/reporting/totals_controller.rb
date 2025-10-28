# frozen_string_literal: true

class API::Reporting::TotalsController < API::Reporting::BaseController
  # Maps query param names to model attribute names
  FILTERS = {
    academic_year: :academic_year,
    programme: :programme_type,
    team_id: :team_id,
    organisation_id: :organisation_id,
    gender: :patient_gender_code,
    year_group: :patient_year_group,
    school_local_authority: :patient_school_local_authority_code,
    local_authority: :patient_local_authority_code
  }.freeze

  GROUPS = {
    local_authority: :patient_local_authority_code,
    school: :patient_school_name,
    year_group: :patient_year_group,
    gender: :patient_gender_code
  }.freeze

  GROUP_HEADERS = {
    patient_local_authority_code: "Local Authority",
    patient_school_name: "School",
    patient_year_group: "Year Group",
    patient_gender_code: "Gender"
  }.freeze

  METRIC_HEADERS = {
    cohort: "Cohort",
    vaccinated: "Vaccinated",
    not_vaccinated: "Not Vaccinated",
    vaccinated_by_sais: "Vaccinated by SAIS",
    vaccinated_elsewhere_declared: "Vaccinated Elsewhere (Declared)",
    vaccinated_elsewhere_recorded: "Vaccinated Elsewhere (Recorded)",
    vaccinated_previously: "Vaccinated Previously"
  }.freeze

  before_action :set_default_filters, :set_filters, :set_scope

  # GET /api/reporting/totals
  # Params:
  # - all keys in the FILTERS constant can be passed to filter the results returned
  #   e.g. academic_year=2024&team_id=1&programme=flu
  #
  # Returns JSON object with:
  #   - cohort: integer - total distinct patients
  #   - vaccinated: integer - patients with administered outcomes
  #   - not_vaccinated: integer - cohort minus vaccinated
  #   - vaccinated_by_sais: integer - same as vaccinated
  #   - vaccinated_elsewhere_declared: integer - patients who declared "already had" vaccination
  #   - vaccinated_elsewhere_recorded: integer - patients with external vaccination records (uploads/NHS API)
  #   - vaccinated_previously: integer - patients vaccinated in prior academic years
  #   - vaccinations_given: integer - total administered records
  #   - monthly_vaccinations_given: array - breakdown by month/year
  #     Each element contains: {year: integer, month: integer, count: integer}
  def index
    respond_to do |format|
      format.csv { render_format_csv }
      format.any { render_format_json }
    end
  end

  private

  def set_default_filters
    params[:academic_year] ||= AcademicYear.current
  end

  def set_filters
    @filters = ReportingAPI::EventFilter.new(params:, filters: FILTERS)
  end

  def set_scope
    @scope =
      ReportingAPI::PatientProgrammeStatus.where(
        organisation_id: current_user.organisation_ids
      ).where(@filters.to_where_clause)

    apply_default_year_group_filter
  end

  def csv_headers(groups)
    headers = {}

    groups.each { |group_attr| headers[GROUP_HEADERS[group_attr]] = group_attr }

    METRIC_HEADERS.each { |attr, header| headers[header] = attr }

    headers
  end

  def render_format_csv
    groups =
      params[:group]
        .to_s
        .split(",")
        .map { GROUPS[it.strip.to_sym] }
        .compact
        .uniq

    @scope = @scope.group(groups).select(groups) if groups.any?
    records = @scope.with_aggregate_metrics

    render_csv records:, header_mappings: csv_headers(groups), prefix: "totals"
  end

  def render_format_json
    render json: {
             cohort: @scope.cohort_count,
             vaccinated: @scope.vaccinated_count,
             not_vaccinated: @scope.not_vaccinated_count,
             vaccinated_by_sais: @scope.vaccinated_by_sais_count,
             vaccinated_elsewhere_declared:
               @scope.vaccinated_elsewhere_declared_count,
             vaccinated_elsewhere_recorded:
               @scope.vaccinated_elsewhere_recorded_count,
             vaccinated_previously: @scope.vaccinated_previously_count,
             vaccinations_given: @scope.vaccinations_given_count,
             monthly_vaccinations_given: @scope.monthly_vaccinations_given
           }
  end

  def apply_default_year_group_filter
    return if params[:year_group].present?
    return if params[:programme].blank?

    programme = Programme.find_by(type: params[:programme])
    return unless programme

    patient_table = ReportingAPI::PatientProgrammeStatus.arel_table
    lpyg_table = Location::ProgrammeYearGroup.arel_table

    subquery =
      lpyg_table
        .project(Arel.star)
        .where(lpyg_table[:location_id].eq(patient_table[:session_location_id]))
        .where(lpyg_table[:programme_id].eq(programme.id))
        .where(lpyg_table[:year_group].eq(patient_table[:patient_year_group]))
        .where(lpyg_table[:academic_year].eq(patient_table[:academic_year]))

    @scope = @scope.where(Arel::Nodes::Exists.new(subquery))
  end
end
