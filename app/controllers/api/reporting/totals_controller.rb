# frozen_string_literal: true

class API::Reporting::TotalsController < API::Reporting::BaseController
  # Maps query param names to model attribute names
  FILTERS = {
    academic_year: :academic_year,
    programme: :programme_type,
    organisation_id: :organisation_id,
    gender: :patient_gender,
    year_group: :patient_year_group,
    school_local_authority: :patient_school_local_authority_code,
    local_authority: :patient_local_authority_code
  }.freeze

  GROUPS = {
    local_authority: :patient_local_authority_code,
    school: %i[patient_school_name patient_school_urn],
    year_group: :patient_year_group,
    gender: :patient_gender
  }.freeze

  GROUP_HEADERS = {
    patient_local_authority_code: "Local Authority",
    patient_school_name: "School",
    patient_school_urn: "School URN",
    patient_year_group: "Year Group",
    patient_gender: "Gender"
  }.freeze

  METRIC_HEADERS = {
    cohort: "Cohort",
    vaccinated: "Vaccinated",
    not_vaccinated: "Not Vaccinated",
    vaccinated_by_sais: "Vaccinated by SAIS",
    vaccinated_elsewhere_declared: "Vaccinated Elsewhere (Declared)",
    vaccinated_elsewhere_recorded: "Vaccinated Elsewhere (Recorded)",
    vaccinated_previously: "Vaccinated Previously",
    consent_given: "Consent Given",
    consent_no_response: "No Consent Response",
    consent_conflicts: "Conflicting Consent",
    parent_refused_consent: "Parent Refused Consent",
    child_refused_vaccination: "Child Refused Vaccination"
  }.freeze

  FLU_SPECIFIC_METRIC_HEADERS = {
    vaccinated_nasal: "Vaccinated (Nasal)",
    vaccinated_injection: "Vaccinated (Injection)",
    consent_given_nasal_only: "Consent Given (Nasal Only)",
    consent_given_injection_only: "Consent Given (Injection Only)",
    consent_given_both_methods: "Consent Given (Both Methods)"
  }.freeze

  before_action :set_default_filters, :set_filters, :set_scope

  # GET /api/reporting/totals
  # Params:
  # - all keys in the FILTERS constant can be passed to filter the results returned
  # - workgroup: team workgroup to filter by (looked up within user's organisations)
  #   e.g. academic_year=2024&workgroup=teamworkgroup&programme=flu
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

    apply_workgroup_filter if params[:workgroup].present?
    apply_default_year_group_filter
  end

  def csv_headers(groups)
    headers = {}

    groups.each { |group_attr| headers[GROUP_HEADERS[group_attr]] = group_attr }

    METRIC_HEADERS.each { |attr, header| headers[header] = attr }

    if params[:programme] == "flu"
      FLU_SPECIFIC_METRIC_HEADERS.each { |attr, header| headers[header] = attr }
    end

    headers
  end

  def render_format_csv
    groups =
      params[:group]
        .to_s
        .split(",")
        .map { GROUPS[it.strip.to_sym] }
        .compact
        .flatten
        .uniq

    @scope = @scope.group(groups).select(groups) if groups.any?
    records = @scope.with_aggregate_metrics

    render_csv records:, header_mappings: csv_headers(groups), prefix: "totals"
  end

  def render_format_json
    response_data = {
      cohort: @scope.cohort_count,
      vaccinated: @scope.vaccinated_count,
      not_vaccinated: @scope.not_vaccinated_count,
      vaccinated_by_sais: @scope.vaccinated_by_sais_count,
      vaccinated_elsewhere_declared: @scope.vaccinated_elsewhere_declared_count,
      vaccinated_elsewhere_recorded: @scope.vaccinated_elsewhere_recorded_count,
      vaccinated_previously: @scope.vaccinated_previously_count,
      vaccinations_given: @scope.vaccinations_given_count,
      monthly_vaccinations_given: @scope.monthly_vaccinations_given,
      consent_given: @scope.consent_given_count,
      consent_no_response: @scope.consent_no_response_count,
      consent_conflicts: @scope.consent_conflicts_count,
      parent_refused_consent: @scope.parent_refused_consent_count,
      child_refused_vaccination: @scope.child_refused_vaccination_count,
      refusal_reasons: consent_refusal_reasons,
      consent_routes: consent_routes_breakdown
    }

    if params[:programme] == "flu"
      response_data.merge!(
        vaccinated_nasal: @scope.vaccinated_nasal_count,
        vaccinated_injection: @scope.vaccinated_injection_count,
        consent_given_nasal_only: @scope.consent_given_nasal_only_count,
        consent_given_injection_only: @scope.consent_given_injection_only_count,
        consent_given_both_methods: @scope.consent_given_both_methods_count
      )
    end

    render json: response_data
  end

  def apply_workgroup_filter
    team =
      Team.find_by(
        workgroup: params[:workgroup],
        organisation_id: current_user.organisation_ids
      )
    @scope = @scope.where(team_id: team.id) if team
  end

  def apply_default_year_group_filter
    return if params[:year_group].present?
    return if params[:programme].blank?

    programme = Programme.find_by(type: params[:programme])
    return unless programme

    patient_table = ReportingAPI::PatientProgrammeStatus.arel_table
    lpyg_table = Location::ProgrammeYearGroup.arel_table
    lyg_table = Location::YearGroup.arel_table

    subquery =
      lpyg_table
        .project(Arel.star)
        .join(lyg_table)
        .on(lpyg_table[:location_year_group_id].eq(lyg_table[:id]))
        .where(lyg_table[:location_id].eq(patient_table[:session_location_id]))
        .where(lyg_table[:value].eq(patient_table[:patient_year_group]))
        .where(lyg_table[:academic_year].eq(patient_table[:academic_year]))
        .where(lpyg_table[:programme_id].eq(programme.id))

    @scope = @scope.where(Arel::Nodes::Exists.new(subquery))
  end

  def consent_refusal_reasons
    Consent
      .joins(:patient)
      .where(
        patient_id: @scope.select(:patient_id),
        programme_id: @scope.select(:programme_id).distinct,
        academic_year: @scope.select(:academic_year).distinct,
        response: :refused
      )
      .not_invalidated
      .not_withdrawn
      .group(:reason_for_refusal)
      .count
  end

  def consent_routes_breakdown
    Consent
      .joins(:patient)
      .where(
        patient_id: @scope.select(:patient_id),
        programme_id: @scope.select(:programme_id).distinct,
        academic_year: @scope.select(:academic_year).distinct
      )
      .not_invalidated
      .not_withdrawn
      .response_provided
      .group(:route)
      .count
  end
end
