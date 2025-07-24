# frozen_string_literal: true

module ReportingAPI
  class TotalsController < ::ReportingAPI::BaseController
    def index
      render json: { total: "some total" }
    end
  end
end
