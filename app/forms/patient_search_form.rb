# frozen_string_literal: true

class PatientSearchForm < SearchForm
  attr_accessor :current_user
  attr_writer :academic_year

  attribute :aged_out_of_programmes, :boolean
  attribute :archived, :boolean
  attribute :consent_statuses, array: true
  attribute :date_of_birth_day, :integer
  attribute :date_of_birth_month, :integer
  attribute :date_of_birth_year, :integer
  attribute :missing_nhs_number, :boolean
  attribute :vaccination_status, :string
  attribute :patient_specific_direction_status, :string
  attribute :programme_types, array: true
  attribute :q, :string
  attribute :register_status, :string
  attribute :triage_status, :string
  attribute :vaccine_method, :string
  attribute :year_groups, array: true

  def initialize(current_user:, session: nil, **attributes)
    @current_user = current_user
    @session = session
    super(**attributes)
  end

  def programme_types=(values)
    super(values&.compact_blank || [])
  end

  def consent_statuses=(values)
    super(values&.compact_blank || [])
  end

  def year_groups=(values)
    super(values&.compact_blank&.map(&:to_i)&.compact || [])
  end

  def programmes
    @programmes ||=
      if programme_types.present?
        Programme.where(type: programme_types)
      else
        @session&.programmes
      end
  end

  def apply(scope)
    scope = filter_name(scope)
    scope = filter_year_groups(scope)
    scope = filter_aged_out_of_programmes(scope)
    scope = filter_archived(scope)
    scope = filter_date_of_birth_year(scope)
    scope = filter_nhs_number(scope)
    scope = filter_programmes(scope)
    scope = filter_consent_statuses(scope)
    scope = filter_vaccination_statuses(scope)
    scope = filter_register_status(scope)
    scope = filter_triage_status(scope)
    scope = filter_vaccine_method(scope)
    scope = filter_patient_specific_direction_status(scope)

    scope.order_by_name
  end

  private

  def academic_year =
    @session&.academic_year || @academic_year || AcademicYear.pending

  def team = @session&.team || @current_user.selected_team

  def filter_name(scope)
    q.present? ? scope.search_by_name(q) : scope
  end

  def filter_year_groups(scope)
    if year_groups.present?
      scope.search_by_year_groups(year_groups, academic_year:)
    else
      scope
    end
  end

  def filter_aged_out_of_programmes(scope)
    if aged_out_of_programmes
      scope.not_appear_in_programmes(team.programmes, academic_year:)
    elsif @session || archived
      scope
    else
      # Archived patients won't appear in programmes, so we need to
      # skip this check if we're trying to view archived patients.
      scope.appear_in_programmes(team.programmes, academic_year:)
    end
  end

  def filter_archived(scope)
    if archived
      scope.archived(team:)
    elsif @session
      scope
    else
      scope.not_archived(team:)
    end
  end

  def filter_date_of_birth_year(scope)
    if date_of_birth_year.present?
      scope = scope.search_by_date_of_birth_year(date_of_birth_year)
    end

    if date_of_birth_month.present?
      scope = scope.search_by_date_of_birth_month(date_of_birth_month)
    end

    if date_of_birth_day.present?
      scope = scope.search_by_date_of_birth_day(date_of_birth_day)
    end

    scope
  end

  def filter_nhs_number(scope)
    missing_nhs_number.present? ? scope.search_by_nhs_number(nil) : scope
  end

  def filter_programmes(scope)
    if programmes.present?
      if @session
        scope.joins(:patient, :session).appear_in_programmes(programmes)
      else
        scope.appear_in_programmes(programmes, academic_year:)
      end
    else
      scope
    end
  end

  def filter_consent_statuses(scope)
    if (statuses = consent_statuses).present?
      given_with_vaccine_method_statuses, other_statuses =
        statuses.partition { it.starts_with?("given_") }

      given_with_vaccine_method_scope =
        if given_with_vaccine_method_statuses.any?
          vaccine_methods =
            given_with_vaccine_method_statuses.map { it.sub("given_", "") }

          if @session
            scope.has_consent_status(
              "given",
              programme: programmes,
              vaccine_method: vaccine_methods
            )
          else
            scope.has_consent_status(
              "given",
              programme: programmes,
              academic_year:,
              vaccine_method: vaccine_methods
            )
          end
        end

      other_status_scope =
        if other_statuses.any?
          if @session
            scope.has_consent_status(other_statuses, programme: programmes)
          else
            scope.has_consent_status(
              other_statuses,
              programme: programmes,
              academic_year:
            )
          end
        end

      if given_with_vaccine_method_scope && other_status_scope
        given_with_vaccine_method_scope.or(other_status_scope)
      else
        given_with_vaccine_method_scope || other_status_scope
      end
    else
      scope
    end
  end

  def filter_vaccination_statuses(scope)
    if (status = vaccination_status&.to_sym).present?
      if @session
        scope.has_vaccination_status(status, programme: programmes)
      else
        scope.has_vaccination_status(
          status,
          programme: programmes,
          academic_year:
        )
      end
    else
      scope
    end
  end

  def filter_patient_specific_direction_status(scope)
    return scope if (status = patient_specific_direction_status&.to_sym).blank?

    case status
    when :added
      scope.has_patient_specific_direction(programme: programmes, team:)
    when :not_added
      scope.without_patient_specific_direction(programme: programmes, team:)
    else
      scope
    end
  end

  def filter_register_status(scope)
    if (status = register_status&.to_sym).present?
      scope.has_registration_status(status)
    else
      scope
    end
  end

  def filter_triage_status(scope)
    if (status = triage_status&.to_sym).present?
      if @session
        scope.has_triage_status(status, programme: programmes)
      else
        scope.has_triage_status(status, programme: programmes, academic_year:)
      end
    else
      scope
    end
  end

  def filter_vaccine_method(scope)
    if vaccine_method.present?
      scope.has_vaccine_method(vaccine_method, programme: programmes)
    else
      scope
    end
  end
end
