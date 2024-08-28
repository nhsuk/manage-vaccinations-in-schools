# frozen_string_literal: true

module NHS::PDS
  class << self
    def connection
      NHS::API.connection.tap { |conn| conn.url_prefix = base_url }
    end

    private

    def base_url
      "#{Settings.nhs_api.base_url}/personal-demographics/FHIR/R4"
    end
  end
end
