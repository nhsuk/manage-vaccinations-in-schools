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
    stats_for_programme(programme)
      .except(:eligible_children)
      .map do |key, value|
        string_key = key.to_s
        {
          heading: card_heading_for(string_key, programme:),
          colour: card_colour_for(string_key),
          count: value.to_s,
          link_to: card_link_to_for(string_key, programme:)
        }
      end
  end

  def card_heading_for(key, programme:)
    if key.starts_with?("consent_")
      I18n.t(key[8..], scope: %i[status consent label])
    elsif key == "vaccinated"
      if programme.mmr?
        # TODO: Apply this to all multi-dose programmes (Td/IPV) once we
        #  have confidence in the change.
        "Fully vaccinated"
      else
        I18n.t("status.vaccination.label.vaccinated")
      end
    end
  end

  def card_colour_for(key)
    if key.starts_with?("consent_")
      I18n.t(key[8..], scope: %i[status consent colour])
    elsif key == "vaccinated"
      I18n.t("status.vaccination.colour.vaccinated")
    end
  end

  def card_link_to_for(key, programme:)
    programme_types = [programme.type]

    if key.starts_with?("consent_")
      consent_statuses = [key[8..]]
      consent_statuses << "conflicts" if key == "consent_refused"

      session_consent_path(session, consent_statuses:, programme_types:)
    elsif key == "vaccinated"
      session_patients_path(
        session,
        programme_types: [programme.type],
        vaccination_status: "vaccinated",
        eligible_children: 1
      )
    end
  end

  def eligible_children_count(programme)
    stats_for_programme(programme)[:eligible_children]
  end

  def still_to_vaccinate_count
    session
      .patients
      .includes_statuses
      .consent_given_and_safe_to_vaccinate(
        programmes:,
        academic_year:,
        vaccine_method: nil,
        without_gelatine: nil
      )
      .count
  end

  def stats_for_programme(programme)
    @stats_by_programme ||= {}
    @stats_by_programme[programme.type] ||= Stats::Session.call(
      session,
      programme:
    )
  end
end
