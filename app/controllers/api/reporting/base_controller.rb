# frozen_string_literal: true

require "pagy/extras/jsonapi"

class API::Reporting::BaseController < ActionController::API
  # we need to still include the AuthenticationConcern even though
  # we're not using the authenticate_user! callback, because we call it
  # explicitly after validating the users' JWT in order to use the
  # CIS2 organisation/workgroup validation code
  include AuthenticationConcern
  include ReportingAPI::TokenAuthenticationConcern

  include Pagy::Backend
  include Pagy::JsonApiExtra

  before_action :ensure_reporting_api_feature_enabled
  before_action :authenticate_user_by_jwt!

  private

  def render_paginated_json(records:)
    pagy, this_page_records = pagy(records, json_api: true)

    set_json_headers
    render json: { data: this_page_records, links: pagy_jsonapi_links(pagy) }
  end

  def set_json_headers
    response.headers["Content-Type"] = "application/json"
    response.headers["Last-Modified"] = Time.now.httpdate
  end

  def render_csv(records:, header_mappings:, prefix: "data")
    filename = csv_filename(prefix:)
    set_csv_headers
    send_data to_csv(records:, header_mappings:),
              filename:,
              disposition: :attachment
  end

  def set_csv_headers
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=posts-#{Date.today}.csv"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.now.httpdate
  end

  def csv_filename(prefix: "data")
    "#{prefix}-#{@filters}-#{Time.current.iso8601.gsub(/[\s:+]/, "")}.csv"
  end

  def ensure_reporting_api_feature_enabled
    render status: :forbidden and return unless Flipper.enabled?(:reporting_api)
  end

  # convert a relation to a csv file,
  # given a mapping of header names to attribute names
  # e.g. { 'Local Authority' => :patient_local_authority_from_postcode_short_name }
  def to_csv(records:, header_mappings:)
    lines = []
    lines << CSV.generate_line(header_mappings.keys)

    records.each do |record|
      values =
        header_mappings.values.map do |attribute_name|
          record[attribute_name]
        rescue StandardError
          nil
        end
      lines << CSV.generate_line(values)
    end
    lines
  end

  def set_default_filters
    params[:filters] ||= AcademicYear.current
  end

  def set_filters
    @filters = ReportingAPI::EventFilter.new(params:, filters:)
  end

  def filters
    raise NoMethodError,
          "Abstract method - filters must be defined on the subclass"
  end
end
