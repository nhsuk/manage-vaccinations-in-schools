# frozen_string_literal: true

class AppPatientTableComponentPreview < ViewComponent::Preview
  def check_consent
    patient_sessions =
      create_list(:patient_session, 2, :triaged_ready_to_vaccinate)

    # add a common name to one of the patients
    patient_sessions.first.patient.update!(common_name: "Bobby")

    render AppPatientTableComponent.new(
             patient_sessions:,
             caption: I18n.t("states.consent_given.title"),
             columns: %i[name dob],
             route: :consent
           )
  end

  def matching_consent_form_to_a_patient
    patient_sessions = create_list(:patient_session, 2, :added_to_session)

    # add a common name to one of the patients above
    patient_sessions.first.patient.update!(common_name: "Bobby")

    # set postcode for both patients
    patient_sessions.each do |ps|
      ps.patient.update!(address_postcode: Faker::Address.postcode)
    end

    consent_form =
      create(:consent_form, session: patient_sessions.first.session)

    render AppPatientTableComponent.new(
             patient_sessions:,
             columns: %i[name postcode dob select_for_matching],
             route: :matching,
             consent_form:
           )
  end
end
