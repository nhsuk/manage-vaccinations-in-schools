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
    scope =
      scope.has_programmes(
        Programme.where(type: programmes)
      ) if programmes.present?

    scope = scope.search_by_name(q) if q.present?

    scope = scope.joins(:location).where(locations: { type: }) if type.present?

    case status
    when "in_progress"
      scope = scope.today
    when "unscheduled"
      scope = scope.unscheduled
    when "scheduled"
      scope = scope.scheduled
    when "completed"
      scope = scope.completed
    end

    scope.sort
  end
end
