# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  SESSION_KEY = "search_filters"

  attribute :clear_filters, :boolean
  attribute :consent_statuses, array: true
  attribute :date_of_birth_day, :integer
  attribute :date_of_birth_month, :integer
  attribute :date_of_birth_year, :integer
  attribute :missing_nhs_number, :boolean
  attribute :programme_status, :string
  attribute :q, :string
  attribute :register_status, :string
  attribute :session_status, :string
  attribute :triage_status, :string
  attribute :vaccine_method, :string
  attribute :year_groups, array: true

  attr_accessor :session, :request_path

  def initialize(params = {})
    super(params)
    handle_session_filters
  end

  def consent_statuses=(values)
    super(values&.compact_blank || [])
  end

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

    if (statuses = consent_statuses).present?
      scope = scope.has_consent_status(statuses, programme:)
    end

    if (status = programme_status&.to_sym).present?
      scope = scope.has_vaccination_status(status, programme:)
    end

    if (status = session_status&.to_sym).present?
      scope = scope.has_session_status(status, programme:)
    end

    if (status = register_status&.to_sym).present?
      scope = scope.has_registration_status(status)
    end

    if (status = triage_status&.to_sym).present?
      scope = scope.has_triage_status(status, programme:)
    end

    if vaccine_method.present?
      scope = scope.has_vaccine_method(vaccine_method, programme:)
    end

    scope.order_by_name
  end

  private

  def handle_session_filters
    if clear_filters
      clear_from_session
    elsif has_filters?
      store_in_session
    else
      load_from_session
    end
  end

  def store_in_session
    return if session.nil?

    if has_filters?
      session[SESSION_KEY] ||= {}
      session[SESSION_KEY][path_key] = attributes
    end
  end

  def load_from_session
    return if session.nil? || session[SESSION_KEY].blank?

    stored_filters = session[SESSION_KEY][path_key]
    return if stored_filters.blank?

    assign_attributes(stored_filters)
  end

  def clear_from_session
    return if session.nil? || session[SESSION_KEY].blank?

    session[SESSION_KEY].delete(path_key)
  end

  def has_filters?
    # An empty string represents the "Any" option
    attributes
      .except(:clear_filters)
      .values
      .any? { it.present? || it == "" || it == [] }
  end

  def path_key
    # 8 should be more than enough to avoid collisions
    # for the number of distinct paths.
    Digest::MD5.hexdigest(request_path).first(8)
  end
end
