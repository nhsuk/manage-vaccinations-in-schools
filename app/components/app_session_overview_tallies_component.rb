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
    stats = stats_for_programme(programme)

    [
      {
        heading: "No response",
        colour: "grey",
        count: stats[:no_response].to_s,
        link_to:
          session_consent_path(
            session,
            consent_statuses: %w[no_response],
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
              count: stats[:"consent_given_#{vaccine_method}"].to_s,
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
              count: stats[:consent_given].to_s,
              link_to:
                session_consent_path(
                  session,
                  consent_statuses: %w[given],
                  programme_types: [programme.type]
                )
            }
          ]
        end
      ),
      {
        heading: "Did not consent",
        colour: "red",
        count: stats[:did_not_consent].to_s,
        link_to:
          session_consent_path(
            session,
            consent_statuses: %w[refused conflicts],
            programme_types: [programme.type]
          )
      },
      {
        heading: "Vaccinated",
        colour: "green",
        count: stats[:vaccinated].to_s,
        link_to:
          session_patients_path(
            session,
            programme_types: [programme.type],
            vaccination_status: "vaccinated",
            eligible_children: 1
          )
      }
    ].flatten
  end

  def eligible_children_count(programme)
    stats_for_programme(programme)[:eligible_children]
  end

  def still_to_vaccinate_count
    session
      .patients
      .includes(:consent_statuses, :triage_statuses, :vaccination_statuses)
      .consent_given_and_safe_to_vaccinate(
        programmes:,
        academic_year:,
        vaccine_method: nil
      )
      .count
  end

  def stats_for_programme(programme)
    @stats_by_programme ||= {}
    @stats_by_programme[programme.id] ||= Stats::Session.call(
      session:,
      programme:
    )
  end
end
