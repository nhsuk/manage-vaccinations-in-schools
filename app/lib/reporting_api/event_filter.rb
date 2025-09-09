# frozen_string_literal: true

module ReportingAPI
  class EventFilter
    attr_accessor :params, :filters

    # params: { (param name): (value) }
    # filters: { (param_name): (attribute_name) }
    def initialize(params:, filters:)
      @params = params
      @filters = filters
    end

    #
    # Returns a hash of (attribute name) => (value of param with that name)
    # suitable for use in a .where(...) clause
    def to_where_clause
      filters.each_with_object({}) do |(param, attr), hash|
        hash[attr] = params[param] if params[param].present?
      end
    end

    # Returns a string with all non-nil params conatenated. Used in
    # generating CSV filenames for filtered recordsets
    def to_s
      with_values =
        filters.filter_map do |param, _attr_name|
          params[param] ? [param.to_s, params[param]].join("_") : nil
        end
      with_values.map { |e| e.gsub(/[^a-z0-9_]+/i, "_") }.join("_")
    end
  end
end
