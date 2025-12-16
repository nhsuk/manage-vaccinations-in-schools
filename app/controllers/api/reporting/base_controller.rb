# frozen_string_literal: true

class API::Reporting::BaseController < ActionController::API
  # we need to still include the AuthenticationConcern even though
  # we're not using the authenticate_user! callback, because we call it
  # explicitly after validating the users' JWT in order to use the
  # CIS2 organisation/workgroup validation code
  include AuthenticationConcern
  include ReportingAPI::TokenAuthenticationConcern

  # Must include this explicitly to use respond_to in an API controller
  include ActionController::MimeResponds
  respond_to :csv, :json

  include Pagy::Backend
  include Pagy::JsonApiExtra

  include UserSessionLoggingConcern

  before_action :ensure_reporting_api_feature_enabled
  before_action :authenticate_user_by_jwt!

  private

  def render_paginated_json(records:)
    pagy, this_page_records = pagy(records, jsonapi: true)

    set_json_headers
    render json: { data: this_page_records, links: pagy_jsonapi_links(pagy) }
  end

  def set_json_headers
    response.headers["Last-Modified"] = Time.zone.now.httpdate
  end

  def render_csv(records:, header_mappings:, prefix: "data")
    filename = csv_filename(prefix:)
    set_csv_headers(filename:)
    send_data to_csv(records:, header_mappings:),
              filename:,
              disposition: :attachment
  end

  def set_csv_headers(filename:)
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=#{filename}"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.zone.now.httpdate
  end

  def csv_filename(prefix: "data", timestamp: Time.current)
    "#{prefix}-#{@filters}-#{timestamp.iso8601.gsub(/[^[:alnum:]]+/, "")}.csv"
  end

  def ensure_reporting_api_feature_enabled
    render status: :forbidden and return unless Flipper.enabled?(:reporting_api)
  end

  # convert a relation to a csv file,
  # given a mapping of header names to attribute names
  # e.g. { 'Local Authority' => :patient_local_authority_from_postcode_short_name }
  def to_csv(records:, header_mappings:)
    CSV.generate(headers: header_mappings.keys, write_headers: true) do |csv|
      records.each do |record|
        csv << header_mappings.values.map { |attr_name| record[attr_name] }
      end
    end
  end
end
