# frozen_string_literal: true

class AppSessionOverviewComponent < ViewComponent::Base
  def initialize(session)
    @session = session
  end

  private

  attr_reader :session

  delegate :academic_year, :dates, :location, :programmes, :team, to: :session

  delegate :grid_column_class,
           :govuk_table,
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
    stats =
      stats_for_programme(programme).except(:eligible_children).stringify_keys

    stats.map { |key, value| card_for(key, value, programme:) }
  end

  def card_for(key, value, programme:)
    {
      heading: card_heading_for(key),
      colour: card_colour_for(key),
      count: value.to_s,
      link_to: card_link_to_for(key, programme:)
    }
  end

  def card_heading_for(key)
    I18n.t(key, scope: %i[status programme label])
  end

  def card_colour_for(key)
    I18n.t(key, scope: %i[status programme colour])
  end

  def card_link_to_for(key, programme:)
    programme_types = [programme.type]

    if programme.flu? && key.starts_with?("due_")
      case key
      when "due_nasal"
        session_patients_path(
          session,
          programme_types:,
          programme_status_group: "due",
          eligible_children: 1,
          vaccine_criteria: %w[flu_nasal flu_nasal_injection]
        )
      when "due_injection"
        session_patients_path(
          session,
          programme_types:,
          programme_status_group: "due",
          eligible_children: 1,
          vaccine_criteria: %w[flu_injection_without_gelatine]
        )
      end
    elsif programme.mmr? && key.starts_with?("due_")
      case key
      when "due_no_preference"
        session_patients_path(
          session,
          programme_types:,
          programme_status_group: "due",
          eligible_children: 1,
          vaccine_criteria: %w[mmr_injection]
        )
      when "due_without_gelatine"
        session_patients_path(
          session,
          programme_types:,
          programme_status_group: "due",
          eligible_children: 1,
          vaccine_criteria: %w[mmr_injection_without_gelatine]
        )
      end
    else
      session_patients_path(
        session,
        programme_types:,
        programme_status_group: key,
        eligible_children: 1,
        vaccine_criteria: []
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
        vaccine_methods: nil,
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
