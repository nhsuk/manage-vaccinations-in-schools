# frozen_string_literal: true

class API::Testing::LocationsController < API::Testing::BaseController
  def index
    @locations = Location.order(:name)

    if (type = params[:type]).present?
      @locations = @locations.where(type:)
    end

    if (status = params[:status]).present?
      @locations = @locations.where(status: status)
    end

    if (gias_year_groups = params[:gias_year_groups]).present?
      @locations = @locations.has_gias_year_groups(gias_year_groups)
    end

    if (is_attached_to_team = params[:is_attached_to_team]).present?
      @locations =
        if ActiveModel::Type::Boolean.new.cast(is_attached_to_team)
          @locations.where.not(subteam_id: nil)
        else
          @locations.where(subteam_id: nil)
        end
    end

    render json: @locations
  end
end
