# frozen_string_literal: true

class PatientSearchForm < SearchForm
  attr_writer :academic_year

  attribute :aged_out_of_programmes, :boolean
  attribute :archived, :boolean
  attribute :consent_statuses, array: true
  attribute :date_of_birth_day, :integer
  attribute :date_of_birth_month, :integer
  attribute :date_of_birth_year, :integer
  attribute :eligible_children, :boolean
  attribute :missing_nhs_number, :boolean
  attribute :patient_specific_direction_status, :string
  attribute :programme_types, array: true
  attribute :q, :string
  attribute :register_status, :string
  attribute :still_to_vaccinate, :boolean
  attribute :triage_status, :string
  attribute :vaccination_status, :string
  attribute :vaccine_criteria, :string
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
        session&.programmes || []
      end
  end

  def vaccine_method
    return nil if vaccine_criteria.blank?

    case vaccine_criteria
    when "injection", "injection_without_gelatine"
      "injection"
    when "nasal"
      "nasal"
    else
      raise "Unknown vaccine criteria value: #{value}"
    end
  end

  def without_gelatine
    return nil if vaccine_criteria.blank?

    case vaccine_criteria
    when "injection", "nasal"
      false
    when "injection_without_gelatine"
      true
    else
      raise "Unknown vaccine criteria value: #{value}"
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
    scope = filter_vaccine_criteria(scope)
    scope = filter_patient_specific_direction_status(scope)
    scope = filter_for_eligible_children_only(scope)

    scope = scope.order_by_name

    filter_still_to_vaccinate(scope)
  end

  private

  attr_reader :current_user, :session

  def academic_year =
    session&.academic_year || @academic_year || AcademicYear.pending

  def team = session&.team || current_user.selected_team

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
    elsif session || archived
      # Archived patients won't appear in programmes, so we need to
      # skip this check if we're trying to view archived patients.
      scope
    else
      scope.appear_in_programmes(team.programmes, academic_year:)
    end
  end

  def filter_archived(scope)
    if archived
      scope.archived(team:)
    elsif session
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
    if programme_types.present?
      if session
        scope.appear_in_programmes(programmes, session:)
      else
        scope.appear_in_programmes(programmes, academic_year:)
      end
    else
      scope
    end
  end

  def filter_consent_statuses(scope)
    if (statuses = consent_statuses).present?
      given_statuses, other_statuses =
        statuses.partition { it.starts_with?("given") }

      given_scope =
        if given_statuses.any?
          or_scope = consent_status_scope_for(given_statuses.first, scope)

          given_statuses
            .drop(1)
            .each do |value|
              or_scope = or_scope.or(consent_status_scope_for(value, scope))
            end

          or_scope
        end

      other_scope =
        if other_statuses.any?
          scope.has_consent_status(
            other_statuses,
            programme: programmes,
            academic_year:
          )
        end

      if given_scope && other_scope
        given_scope.or(other_scope)
      else
        given_scope || other_scope
      end
    else
      scope
    end
  end

  def consent_status_scope_for(value, scope)
    case value
    when "given"
      scope.has_consent_status(
        "given",
        programme: programmes,
        academic_year:,
        vaccine_method: "injection",
        without_gelatine: false
      )
    when "given_nasal"
      scope.has_consent_status(
        "given",
        programme: programmes,
        academic_year:,
        vaccine_method: "nasal",
        without_gelatine: false
      )
    when "given_injection_without_gelatine"
      scope.has_consent_status(
        "given",
        programme: programmes,
        academic_year:,
        vaccine_method: "injection",
        without_gelatine: true
      )
    else
      raise "Unknown consent filter value: #{value}"
    end
  end

  def filter_vaccination_statuses(scope)
    if (status = vaccination_status&.to_sym).present?
      scope.has_vaccination_status(
        status,
        programme: programmes,
        academic_year:
      )
    else
      scope
    end
  end

  def filter_patient_specific_direction_status(scope)
    return scope if (status = patient_specific_direction_status&.to_sym).blank?

    case status
    when :added
      scope.with_patient_specific_direction(
        programme: programmes,
        academic_year:,
        team:
      )
    when :not_added
      scope.without_patient_specific_direction(
        programme: programmes,
        academic_year:,
        team:
      )
    else
      scope
    end
  end

  def filter_register_status(scope)
    if (status = register_status&.to_sym).present?
      scope.has_registration_status(status, session:)
    else
      scope
    end
  end

  def filter_triage_status(scope)
    if (status = triage_status&.to_sym).present?
      scope.has_triage_status(status, programme: programmes, academic_year:)
    else
      scope
    end
  end

  def filter_vaccine_criteria(scope)
    return scope if vaccine_criteria.blank?

    scope.has_vaccine_criteria(
      vaccine_method:,
      without_gelatine:,
      programme: programmes,
      academic_year:
    )
  end

  def filter_still_to_vaccinate(scope)
    return scope if still_to_vaccinate.blank?

    scope.consent_given_and_safe_to_vaccinate(
      programmes:,
      academic_year:,
      vaccine_method:,
      without_gelatine:
    )
  end

  def filter_for_eligible_children_only(scope)
    return scope if eligible_children.blank?

    scope.not_deceased.eligible_for_programmes(
      programmes,
      location: session.location,
      academic_year:
    )
  end
end
