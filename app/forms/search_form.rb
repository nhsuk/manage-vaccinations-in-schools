# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attr_accessor :session

  attribute :consent_status, :string
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
  attribute :year_groups, array: true

  def programme_types=(values)
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
        session&.programmes
      end
  end

  def apply(scope)
    scope = scope.search_by_name(q) if q.present?

    scope = scope.search_by_year_groups(year_groups) if year_groups.present?

    if date_of_birth_year.present?
      scope = scope.search_by_date_of_birth_year(date_of_birth_year)
    end

    if date_of_birth_month.present?
      scope = scope.search_by_date_of_birth_month(date_of_birth_month)
    end

    if date_of_birth_day.present?
      scope = scope.search_by_date_of_birth_day(date_of_birth_day)
    end

    scope = scope.search_by_nhs_number(nil) if missing_nhs_number.present?

    scope = scope.in_programmes(programmes) if programmes.present?

    if (status = consent_status).present?
      scope = scope.has_consent_status(status, programme: programmes)
    end

    if (status = programme_status&.to_sym).present?
      scope = scope.has_vaccination_status(status, programme: programmes)
    end

    if (status = session_status&.to_sym).present?
      scope = scope.has_session_status(status, programme: programmes)
    end

    if (status = register_status&.to_sym).present?
      scope = scope.has_registration_status(status)
    end

    if (status = triage_status&.to_sym).present?
      scope = scope.has_triage_status(status, programme: programmes)
    end

    scope.order_by_name
  end
end
