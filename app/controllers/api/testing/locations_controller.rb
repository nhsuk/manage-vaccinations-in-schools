# frozen_string_literal: true

class API::Testing::LocationsController < API::Testing::BaseController
  include ActionController::Live

  def index
    @locations = Location.includes(:team_locations).order(:name)

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
      academic_year = AcademicYear.pending

      exists_subquery =
        TeamLocation
          .where("team_locations.location_id = locations.id")
          .where(academic_year:)
          .arel
          .exists

      @locations =
        if ActiveModel::Type::Boolean.new.cast(is_attached_to_team)
          @locations.where(exists_subquery)
        else
          @locations.where.not(exists_subquery)
        end
    end

    render json: @locations
  end

  def destroy
    workgroup = params[:workgroup]
    keep_base_locations = params[:keep_base_locations]

    return render json: { error: "workgroup is required" }, status: :bad_request if workgroup.blank?

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"

    team = Team.find_by!(workgroup:)
    team_id = team.id

    location_ids = TeamLocation.where(team_id: team_id).pluck(:location_id)

    locations = Location.where(id: location_ids)

    keep_base_locations = ActiveModel::Type::Boolean.new.cast(keep_base_locations)

    if keep_base_locations
      locations = Location.where(id: location_ids).where.not(site: [nil, "A"])
    end

    location_ids_to_delete = locations.pluck(:id)

    log_destroy(AttendanceRecord.where(location_id: location_ids_to_delete))
    log_destroy(ClassImport.where(location_id: location_ids_to_delete))
    log_destroy(GillickAssessment.where(location_id: location_ids_to_delete))
    log_destroy(PatientLocation.where(location_id: location_ids_to_delete))
    log_destroy(PreScreening.where(location_id: location_ids_to_delete))

    log_destroy(Session.where(team_location_id: TeamLocation.where(location_id: location_ids_to_delete).pluck(:id)))
    log_destroy(TeamLocation.where(location_id: location_ids_to_delete))

    log_destroy(VaccinationRecord.where(location_id: location_ids_to_delete))

    location_year_group_ids = Location::YearGroup.where(location_id: location_ids_to_delete).pluck(:id)
    log_destroy(Location::ProgrammeYearGroup.where(location_year_group_id: location_year_group_ids))
    log_destroy(Location::YearGroup.where(location_id: location_ids_to_delete))
    log_destroy(locations)

    if keep_base_locations
      Location.where(id: location_ids, site: "A").update_all(site: nil)
    end

    response.stream.write "Done"
  rescue StandardError => e
    response.status = :internal_server_error
    response.stream.write "Error: #{e.message}\n"
  ensure
    response.stream.close
  end

  private

  def log_destroy(query)
    where_clause = query.where_clause
    @log_time ||= Time.zone.now
    query.delete_all
    response.stream.write(
      "#{query.model.name}.where(#{where_clause.to_h}): #{Time.zone.now - @log_time}s\n"
    )
    @log_time = Time.zone.now
  end
end
