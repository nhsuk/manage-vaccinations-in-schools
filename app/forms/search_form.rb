# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attribute :consent_status, :string
  attribute :date_of_birth_day, :integer
  attribute :date_of_birth_month, :integer
  attribute :date_of_birth_year, :integer
  attribute :missing_nhs_number, :boolean
  attribute :programme_status, :string
  attribute :q, :string
  attribute :register_status, :string
  attribute :session_status, :string
  attribute :triage_status, :string
  attribute :year_groups, array: true

  def year_groups=(values)
    super(values&.compact_blank&.map(&:to_i)&.compact || [])
  end

  def apply(scope, programme: nil)
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

    scope = scope.order_by_name

    scope = yield(scope) if block_given?

    if (status = consent_status&.to_sym).present?
      scope =
        scope.select do
          it
            .patient
            .consent_outcome
            .status
            .values_at(*it.programmes)
            .include?(status)
        end
    end

    if (status = programme_status&.to_sym).present?
      scope = scope.select { it.programme_outcome.status[programme] == status }
    end

    if (status = session_status&.to_sym).present?
      scope = scope.select { it.session_outcome.status.values.include?(status) }
    end

    if (status = register_status&.to_sym).present?
      scope = scope.select { it.register_outcome.status == status }
    end

    if (status = triage_status&.to_sym).present?
      scope =
        scope.select do
          it
            .patient
            .triage_outcome
            .status
            .values_at(*it.programmes)
            .include?(status)
        end
    end

    scope
  end
end
