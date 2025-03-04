# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attribute :date_of_birth, :date
  attribute :missing_nhs_number, :boolean
  attribute :q, :string
  attribute :year_groups, array: true

  def year_groups=(values)
    super(values.compact_blank.map(&:to_i).compact)
  end

  def apply(scope)
    scope = scope.search_by_name(q) if q.present?

    scope = scope.search_by_year_groups(year_groups) if year_groups.present?

    scope =
      scope.search_by_date_of_birth(date_of_birth) if date_of_birth.present?

    scope = scope.search_by_nhs_number(nil) if missing_nhs_number.present?

    scope.order_by_name
  end
end
