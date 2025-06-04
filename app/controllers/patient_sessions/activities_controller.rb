# frozen_string_literal: true

class PatientSessions::ActivitiesController < PatientSessions::BaseController
  before_action :record_access_log_entry, only: :show

  def show
  end

  private

  def access_log_entry_action = "log"
end
