module PatientSortingConcern
  extend ActiveSupport::Concern

  SORT_MAPPING = {
    "name" => "patient.full_name",
    "dob" => "patient.date_of_birth",
    "outcome" => "state"
  }.freeze

  def sort_patients!(patient_sessions)
    return if params[:sort].blank?

    method_path = SORT_MAPPING[params[:sort]]
    patient_sessions.sort_by! { deep_send(_1, method_path) }
    patient_sessions.reverse! if params[:direction] == "desc"
  end

  private

  def deep_send(object, method_path)
    method_path.split(".").reduce(object) { |o, m| o.send(m) }
  end
end
