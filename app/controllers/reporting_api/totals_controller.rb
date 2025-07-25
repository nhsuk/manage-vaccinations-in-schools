# frozen_string_literal: true

module ReportingAPI
  class TotalsController < BaseController
    def index
      render json: { total: "some total" }
    end
  end
end
