class PatientSessionsController < ApplicationController
  before_action :set_patient_session
  before_action :set_session
  before_action :set_patient
  before_action :set_route
  before_action :set_back_link

  layout "two_thirds", except: :index

  def show
  end

  private

  def set_patient_session
    @patient_session = policy_scope(PatientSession).find(params.fetch(:id))
  end

  def set_session
    @session = @patient_session.session
  end

  def set_patient
    @patient = @patient_session.patient
  end

  def set_route
    @route = params[:route]
  end

  def set_back_link
    @back_link = vaccinations_session_path(@session)
  end
end
