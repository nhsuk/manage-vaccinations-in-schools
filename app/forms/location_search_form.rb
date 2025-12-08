# frozen_string_literal: true

class LocationSearchForm < SearchForm
  attribute :q, :string
  attribute :phase, :string

  def apply(scope)
    scope = filter_phase(scope)
    scope = filter_name(scope)

    scope.order_by_name
  end

  private

  def filter_phase(scope)
    phase.present? ? scope.where_phase(phase) : scope
  end

  def filter_name(scope)
    q.present? ? scope.search_by_name(q) : scope
  end
end
