# frozen_string_literal: true

class AppSessionPatientTableComponentPreview < ViewComponent::Preview
  include FactoryBot::Syntax::Methods

  def check_consent
    patient_sessions =
      create_list(:patient_session, 2, :triaged_ready_to_vaccinate)

    # add a common name to one of the patients
    patient_sessions.first.patient.update!(common_name: "Bobby")

    render AppSessionPatientTableComponent.new(
             session: patient_sessions.first.session,
             patient_sessions:,
             caption: I18n.t("states.consent_given.title"),
             columns: %i[name year_group],
             route: :consent
           )
  end

  def matching_consent_form_to_a_patient
    programme = create(:programme)
    patient_sessions =
      create_list(:patient_session, 2, :added_to_session, programme:)

    # add a common name to one of the patients above
    patient_sessions.first.patient.update!(common_name: "Bobby")

    # set postcode for both patients
    patient_sessions.each do |ps|
      ps.patient.update!(address_postcode: Faker::Address.postcode)
    end

    session = patient_sessions.first.session

    consent_form = create(:consent_form, programme:, session:)

    render AppSessionPatientTableComponent.new(
             session:,
             patient_sessions:,
             columns: %i[name postcode year_group select_for_matching],
             route: :matching,
             consent_form:
           )
  end
end
