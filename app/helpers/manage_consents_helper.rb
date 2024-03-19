module ManageConsentsHelper
  def form_path_for(consent)
    consent.recorded? ? clone_session_patient_manage_consent_path : wizard_path
  end

  def form_method_for(consent)
    consent.recorded? ? :post : :put
  end

  def include_clone_fields_for(consent)
    consent.recorded?
  end
end
