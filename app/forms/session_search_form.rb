# frozen_string_literal: true

class SessionSearchForm < SearchForm
  attribute :programmes, array: true
  attribute :q, :string
  attribute :status, :string
  attribute :type, :string

  def programmes=(values)
    super(values&.compact_blank || [])
  end

  def apply(scope)
    scope = filter_programmes(scope)
    scope = filter_name(scope)
    scope = filter_type(scope)
    scope = filter_status(scope)

    scope.sort
  end

  private

  def filter_programmes(scope)
    if programmes.present?
      scope.has_programmes(Programme.where(type: programmes))
    else
      scope
    end
  end

  def filter_name(scope)
    q.present? ? scope.search_by_name(q) : scope
  end

  def filter_type(scope)
    type.present? ? scope.joins(:location).where(locations: { type: }) : scope
  end

  def filter_status(scope)
    case status
    when "in_progress"
      scope.today
    when "unscheduled"
      scope.unscheduled
    when "scheduled"
      scope.scheduled
    when "completed"
      scope.completed
    else
      scope
    end
  end
end
