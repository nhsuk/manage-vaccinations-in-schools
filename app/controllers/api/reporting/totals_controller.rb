# frozen_string_literal: true

class API::Reporting::TotalsController < API::Reporting::BaseController
  def index
    render json: { total: "dummy data" }
  end
end
