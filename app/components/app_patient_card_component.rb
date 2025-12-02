# frozen_string_literal: true

class AppPatientCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(section: true) do |card| %>
      <% card.with_heading(level: heading_level) { "Child’s details" } %>
      
      <% important_notices.each do |notice| %>
        <%= render AppStatusComponent.new(text: notice) %>
      <% end %>

      <%= render AppChildSummaryComponent.new(
        patient,
        current_team:,
        show_parents: true,
        show_school_and_year_group:,
        change_links:,
        remove_links:
      ) %>

      <%= content %>
    <% end %>
  ERB

  def initialize(
    patient,
    current_team:,
    change_links: {},
    remove_links: {},
    heading_level: 3
  )
    @patient = patient
    @current_team = current_team
    @change_links = change_links
    @remove_links = remove_links
    @heading_level = heading_level
  end

  private

  attr_reader :patient,
              :current_team,
              :change_links,
              :remove_links,
              :heading_level

  def show_school_and_year_group = patient.show_year_group?(team: current_team)

  def important_notices
    notices = patient.important_notices.where(team_id: current_team.id)

    [
      (
        if patient.restricted?
          notices.restricted.order(recorded_at: :desc).first&.message
        end
      ),
      (
        if patient.invalidated?
          notices.invalidated.order(recorded_at: :desc).first&.message
        end
      ),
      *notices.deceased.first&.message,
      *gillick_no_notify_notices,
      *team_changed_notices
    ].compact
  end

  def gillick_no_notify_notices
    no_notify_vaccination_records =
      patient.vaccination_records.select do
        it.notify_parents == false && it.team == current_team
      end

    if no_notify_vaccination_records.any?
      vaccinations_sentence =
        "#{no_notify_vaccination_records.map(&:programme).uniq.map(&:name).to_sentence} " \
          "#{"vaccination".pluralize(no_notify_vaccination_records.length)}"

      "Child gave consent for #{vaccinations_sentence} under Gillick competence and " \
        "does not want their parents to be notified. " \
        "These records will not be automatically synced with GP records. " \
        "Your team must let the child's GP know they were vaccinated."
    end
  end

  def team_changed_notices
    return unless patient.school

    valid_notices =
      patient
        .important_notices
        .team_changed
        .includes(:school_move_log_entry)
        .where(team: current_team)
        .where.not(team: patient.school.teams)

    valid_notices.map(&:message)
  end
end
