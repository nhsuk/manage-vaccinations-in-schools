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

    if (year_groups = params[:year_groups]).present?
      @locations =
        @locations.where("ARRAY[?]::integer[] <@ year_groups", year_groups)
    end

    if (
         is_attached_to_organisation = params[:is_attached_to_organisation]
       ).present?
      @locations =
        if ActiveModel::Type::Boolean.new.cast(is_attached_to_organisation)
          @locations.where.not(team_id: nil)
        else
          @locations.where(team_id: nil)
        end
    end

    render json: @locations
  end
end
