# frozen_string_literal: true

module ReportingAPI
  class EventFilter
    attr_accessor :params, :filters

    def initialize(params:, filters:)
      @params = params
      @filters = filters
    end

    # Expects a hash of params: { (param name) => (value) }
    # and filters: { (param_name): (attribute_name) }
    #
    # Returns a hash of (attribute name) => (value of param with that name)
    # suitable for use in a .where(...) clause
    def to_where_clause
      filters_to_apply = {}
      filters.each do |param, attr|
        filters_to_apply[attr] = params[param] if params[param].present?
      end
      filters_to_apply
    end

    def to_s
      filters
        .map do |param, _attr_name|
          params[param] ? [param.to_s, params[param]].join("_") : nil
        end
        .compact
        .join("_")
    end
  end
end
