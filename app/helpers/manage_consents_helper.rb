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

  # rubocop:disable Rails/HelperInstanceVariable
  def back_link_path
    if @consent.form_steps.first == @current_step
      case @route
      when "consents"
        session_patient_consents_path(@session, @patient)
      when "triage"
        session_patient_triage_path(@session)
      else
        session_patient_vaccinations_path(@session)
      end
    else
      previous_wizard_path
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
