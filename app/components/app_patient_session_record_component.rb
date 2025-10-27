# frozen_string_literal: true

class AppPatientSessionRecordComponent < ViewComponent::Base
  erb_template <<-ERB
    <% if policy(vaccination_record).new? %>
      <h3 class="nhsuk-heading-m"><%= heading %></h3>
      <%= render AppVaccinateFormComponent.new(vaccinate_form) %>
    <% end %>
  ERB

  def initialize(patient:, session:, programme:, current_user:, vaccinate_form:)
    @patient = patient
    @session = session
    @programme = programme
    @current_user = current_user
    @vaccinate_form = vaccinate_form || default_vaccinate_form
  end

  def render?
    session.today? &&
      patient.consent_given_and_safe_to_vaccinate?(
        programme:,
        academic_year:
      ) &&
      (
        registration_status&.attending? || registration_status&.completed? ||
          !session.requires_registration?
      )
  end

  private

  attr_reader :patient, :session, :current_user, :programme, :vaccinate_form

  delegate :policy, to: :helpers
  delegate :academic_year, to: :session

  def registration_status
    @registration_status ||= patient.registration_status(session:)
  end

  def vaccination_record
    VaccinationRecord.new(patient:, session:, programme:)
  end

  def default_vaccinate_form
    pre_screening_confirmed = patient.pre_screenings.today.exists?(programme:)
    session_date = session.session_dates.today.first

    VaccinateForm.new(
      current_user:,
      patient:,
      session_date:,
      programme:,
      pre_screening_confirmed:
    )
  end

  def heading
    vaccine_criteria = patient.vaccine_criteria(programme:, academic_year:)

    vaccination =
      if programme.has_multiple_vaccine_methods?
        vaccine_method = vaccine_criteria.vaccine_methods.first
        method_string =
          Vaccine.human_enum_name(:method, vaccine_method).downcase
        "vaccination with #{method_string}"
      else
        "vaccination"
      end

    render AppVaccineCriteriaComponent.new(vaccine_criteria) do
      "Record #{programme.name_in_sentence} #{vaccination}"
    end
  end
end
