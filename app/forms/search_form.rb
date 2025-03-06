# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attribute :consent_status, :string
  attribute :date_of_birth, :date
  attribute :missing_nhs_number, :boolean
  attribute :q, :string
  attribute :register_status, :string
  attribute :triage_status, :string
  attribute :year_groups, array: true

  def initialize(options)
    super(options)
  rescue ActiveRecord::MultiparameterAssignmentErrors
    super(
      options.except(
        :"date_of_birth(1i)",
        :"date_of_birth(2i)",
        :"date_of_birth(3i)"
      )
    )
  end

  def year_groups=(values)
    super(values&.compact_blank&.map(&:to_i)&.compact || [])
  end

  def apply(scope)
    scope = scope.search_by_name(q) if q.present?

    scope = scope.search_by_year_groups(year_groups) if year_groups.present?

    scope =
      scope.search_by_date_of_birth(date_of_birth) if date_of_birth.present?

    scope = scope.search_by_nhs_number(nil) if missing_nhs_number.present?

    scope = scope.order_by_name

    scope = yield(scope) if block_given?

    if (status = consent_status&.to_sym).present?
      scope = scope.select { it.consent.status.values.include?(status) }
    end

    if (status = register_status&.to_sym).present?
      scope = scope.select { it.register.status == status }
    end

    if (status = triage_status&.to_sym).present?
      scope = scope.select { it.triage.status.values.include?(status) }
    end

    scope
  end
end
