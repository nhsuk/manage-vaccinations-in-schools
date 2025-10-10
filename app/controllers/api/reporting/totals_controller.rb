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

  before_action :set_default_filters, :set_filters

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
    organisation_id = current_user.organisations
    scope =
      ReportingAPI::PatientProgrammeStatus.where(organisation_id:).where(
        @filters.to_where_clause
      )

    render json: {
             cohort: scope.cohort_count,
             vaccinated: scope.vaccinated_count,
             not_vaccinated: scope.not_vaccinated_count,
             vaccinated_by_sais: scope.vaccinated_by_sais_count,
             vaccinated_elsewhere_declared:
               scope.vaccinated_elsewhere_declared_count,
             vaccinated_elsewhere_recorded:
               scope.vaccinated_elsewhere_recorded_count,
             vaccinated_previously: scope.vaccinated_previously_count,
             vaccinations_given: scope.vaccinations_given_count,
             monthly_vaccinations_given: scope.monthly_vaccinations_given
           }
  end

  private

  def set_default_filters
    params[:academic_year] ||= AcademicYear.current
  end

  def set_filters
    @filters = ReportingAPI::EventFilter.new(params:, filters: FILTERS)
  end
end
