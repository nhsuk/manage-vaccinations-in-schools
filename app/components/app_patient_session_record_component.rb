# frozen_string_literal: true

class AppPatientSessionRecordComponent < ViewComponent::Base
  erb_template <<-ERB
    <h3 class="nhsuk-heading-m"><%= heading %></h3>
    
    <% if helpers.policy(VaccinationRecord).new? %>
      <%= render AppVaccinateFormComponent.new(vaccinate_form) %>
    <% end %>
  ERB

  def initialize(patient_session, programme:, vaccinate_form: nil)
    super

    @patient_session = patient_session
    @programme = programme
    @vaccinate_form = vaccinate_form || default_vaccinate_form
  end

  def render?
    patient.consent_given_and_safe_to_vaccinate?(programme:, academic_year:) &&
      (
        patient_session.registration_status&.attending? ||
          patient_session.registration_status&.completed? ||
          !patient_session.session.requires_registration?
      )
  end

  private

  attr_reader :patient_session, :programme, :vaccinate_form

  delegate :patient, :session, to: :patient_session
  delegate :academic_year, to: :session

  def default_vaccinate_form
    pre_screening_confirmed = patient.pre_screenings.today.exists?(programme:)

    VaccinateForm.new(patient_session:, programme:, pre_screening_confirmed:)
  end

  def heading
    vaccination =
      if programme.has_multiple_vaccine_methods?
        vaccine_method =
          patient.approved_vaccine_methods(programme:, academic_year:).first
        method_string =
          Vaccine.human_enum_name(:method, vaccine_method).downcase
        "vaccination with #{method_string}"
      else
        "vaccination"
      end

    tag.span(class: "app-vaccine-method", data: { method: vaccine_method }) do
      "Record #{programme.name_in_sentence} #{vaccination}"
    end
  end
end
