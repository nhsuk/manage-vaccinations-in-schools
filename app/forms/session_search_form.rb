# frozen_string_literal: true

class SessionSearchForm < SearchForm
  attribute :academic_year, :integer
  attribute :programmes, array: true
  attribute :q, :string
  attribute :status, :string
  attribute :type, :string

  def academic_year
    super || AcademicYear.current
  end

  def programmes=(values)
    super(values&.compact_blank || [])
  end

  def apply(scope)
    scope = scope.where(academic_year:)

    scope =
      scope.has_programmes(
        Programme.where(type: programmes)
      ) if programmes.present?

    scope = scope.search_by_name(q) if q.present?

    scope = scope.joins(:location).where(locations: { type: }) if type.present?

    scope = scope.public_send(status) if status.in?(VALID_STATUS_SCOPES)

    scope.sort
  end

  VALID_STATUS_SCOPES = %w[in_progress unscheduled scheduled completed].freeze
end
