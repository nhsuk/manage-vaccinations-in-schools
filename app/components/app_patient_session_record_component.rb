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
    pre_screening_confirmed =
      patient.pre_screenings.today.where_programme(programme).exists?

    VaccinateForm.new(
      current_user:,
      patient:,
      session:,
      programme:,
      pre_screening_confirmed:
    )
  end

  def heading
    vaccine_criteria = patient.vaccine_criteria(programme:, academic_year:)
    render AppVaccineCriteriaLabelComponent.new(
             vaccine_criteria,
             programme:,
             context: :heading
           )
  end
end
