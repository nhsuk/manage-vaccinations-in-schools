# frozen_string_literal: true

class API::Reporting::ConsentsController < API::Reporting::BaseController 

  # param name: attribute_name
  FILTERS = {
    academic_year: :event_timestamp_academic_year,
    team_id: :team_id,
    gender: :patient_gender_code,
    year_group: :patient_year_group,
    programme: :programme_type,
    local_authority: :local_authority_from_postcode,
    school_local_authority: :patient_school_gias_local_authority_code, 
  }

  def index
    params[:academic_year] ||= Date.current.academic_year
    @consents = ReportingAPI::ConsentEvent.where(
      filter_clause(params)
    )
    totals = {
      offered: @consents.where(source_type: "ConsentNotification", event_type: "request").count,
      consented: @consents.where(consent_response: "given").count,
      refused: @consents.where(consent_response: "refused").count,
    }
    
    totals[:no_response] = totals[:offered] - (totals[:consented] + totals[:refused])

    render json: totals
  end

  private

  def filter_clause(params)
    filters = {}
    FILTERS.each do |param, attr|
      filters[attr] = params[param] if params[param].present?
    end
    filters
  end

end