# frozen_string_literal: true

class AppSessionOverviewTalliesComponent < ViewComponent::Base
  def initialize(session)
    @session = session
  end

  private

  attr_reader :session

  delegate :academic_year, :dates, :location, :programmes, to: :session

  delegate :govuk_table,
           :govuk_button_link_to,
           :govuk_inset_text,
           :govuk_summary_list,
           :session_consent_period,
           :policy,
           to: :helpers

  def heading
    if session.completed?
      "All session dates completed"
    elsif session.today?
      "Session in progress"
    else
      "Scheduled session dates"
    end
  end

  def no_sessions_message
    location_context = session.clinic? ? "clinic" : "school"
    "There are currently no sessions scheduled at this #{location_context}."
  end

  def edit_button_text
    dates.empty? ? "Schedule sessions" : "Edit session"
  end

  def cards_for_programme(programme)
    [
      {
        heading: "No response",
        colour: "grey",
        count: consent_count(programme, "no_response").to_s,
        link_to:
          session_consent_path(
            session,
            consent_statuses: ["no_response"],
            programme_types: [programme.type]
          )
      },
      (
        if programme.has_multiple_vaccine_methods?
          programme.vaccine_methods.map do |vaccine_method|
            method_string =
              Vaccine.human_enum_name(:method, vaccine_method).downcase

            {
              heading: "Consent given for #{method_string}",
              colour: "aqua-green",
              count: consent_count(programme, "given", vaccine_method:).to_s,
              link_to:
                session_consent_path(
                  session,
                  consent_statuses: ["given_#{vaccine_method}"],
                  programme_types: [programme.type]
                )
            }
          end
        else
          [
            {
              heading: "Consent given",
              colour: "aqua-green",
              count: consent_count(programme, "given").to_s,
              link_to:
                session_consent_path(
                  session,
                  consent_statuses: ["given"],
                  programme_types: [programme.type]
                )
            }
          ]
        end
      ),
      {
        heading: "Contraindicated or did not consent",
        colour: "red",
        count: could_not_vaccinate_count(programme).to_s,
        link_to:
          session_patients_path(
            session,
            vaccination_status: "could_not_vaccinate",
            programme_types: [programme.type]
          )
      },
      {
        heading: "Vaccinated",
        colour: "green",
        count: vaccinated_count(programme).to_s,
        link_to:
          session_patients_path(
            session,
            vaccination_status: "vaccinated",
            programme_types: [programme.type]
          )
      }
    ].flatten
  end

  def eligible_patients(programme)
    session
      .patients
      .appear_in_programmes([programme], session:)
      .eligible_for_programmes([programme], location:, academic_year:)
  end

  def eligible_cohort_count(programme)
    eligible_patients(programme).count
  end

  def vaccinated_count(programme)
    eligible_patients(programme).has_vaccination_status(
      "vaccinated",
      programme:,
      academic_year:
    ).count
  end

  def could_not_vaccinate_count(programme)
    eligible_patients(programme).has_vaccination_status(
      "could_not_vaccinate",
      programme:,
      academic_year:
    ).count
  end

  def consent_count(programme, status, vaccine_method: nil)
    eligible_patients(programme).has_consent_status(
      status,
      programme:,
      academic_year:,
      vaccine_method:
    ).count
  end

  def no_outcome_count(programme)
    eligible_patients(programme).has_vaccination_status(
      "none_yet",
      programme:,
      academic_year:,
      vaccine_method:
    ).count
  end

  def still_to_vaccinate_count
    session
      .patients
      .consent_given_and_ready_to_vaccinate(
        programmes:,
        academic_year:,
        vaccine_method: nil
      )
      .count
  end
end
