# frozen_string_literal: true

class PatientSearchForm < SearchForm
  attr_writer :academic_year

  attribute :consent_statuses, array: true
  attribute :date_of_birth_day, :integer
  attribute :date_of_birth_month, :integer
  attribute :date_of_birth_year, :integer
  attribute :missing_nhs_number, :boolean
  attribute :programme_status, :string
  attribute :programme_types, array: true
  attribute :q, :string
  attribute :register_status, :string
  attribute :session_status, :string
  attribute :triage_status, :string
  attribute :vaccine_method, :string
  attribute :year_groups, array: true

  def initialize(session: nil, **attributes)
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
    scope = filter_date_of_birth_year(scope)
    scope = filter_nhs_number(scope)
    scope = filter_programmes(scope)
    scope = filter_consent_statuses(scope)
    scope = filter_vaccination_statuses(scope)
    scope = filter_session_status(scope)
    scope = filter_register_status(scope)
    scope = filter_triage_status(scope)
    scope = filter_vaccine_method(scope)

    scope.order_by_name
  end

  private

  def academic_year =
    @session&.academic_year || @academic_year || AcademicYear.current

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
      if @session
        scope.has_consent_status(statuses, programme: programmes)
      else
        scope.has_consent_status(
          statuses,
          programme: programmes,
          academic_year:
        )
      end
    else
      scope
    end
  end

  def filter_vaccination_statuses(scope)
    if (status = programme_status&.to_sym).present?
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

  def filter_session_status(scope)
    if (status = session_status&.to_sym).present?
      scope.has_session_status(status, programme: programmes)
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
