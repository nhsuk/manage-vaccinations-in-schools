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
      filters_to_apply = {}
      filters.each do |param, attr|
        filters_to_apply[attr] = params[param] if params[param].present?
      end
      filters_to_apply
    end

    # Returns a string with all non-nil params conatenated. Used in 
    # generating CSV filenames for filtered recordsets
    def to_s
      filters
        .map do |param, _attr_name|
          params[param] ? [param.to_s, params[param]].join("_") : nil
        end
        .compact
        .map{|e| e.gsub(/[^a-z0-9\_]+/i, '_') }
        .join("_")
    end
  end
end
