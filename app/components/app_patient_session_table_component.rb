# frozen_string_literal: true

class AppPatientSessionTableComponent < ViewComponent::Base
  erb_template <<-ERB
    <% if sessions.any? %>
      <%= govuk_table(html_attributes: { class: "nhsuk-table-responsive" }) do |table| %>
        <% table.with_head do |head| %>
          <% head.with_row do |row| %>
            <% row.with_cell(text: "Location") %>
            <% row.with_cell(text: "Session dates") %>
            <% if @programme_type.nil? %>
              <% row.with_cell(text: "Programme") %>
            <% else %>
              <% row.with_cell(text: "Session outcome") %>
            <% end %>
          <% end %>
        <% end %>

        <% table.with_body do |body| %>
          <% sessions.each do |session| %>
            <% session.programmes_for(patient:).each do |programme| %>
              <% body.with_row do |row| %>
                <% row.with_cell do %>
                  <span class="nhsuk-table-responsive__heading">Location</span>
                  <%= link_to session.location.name,
                              session_patient_programme_path(session, patient, programme) %>
                <% end %>

                <% row.with_cell do %>
                  <span class="nhsuk-table-responsive__heading">Session dates</span>
                  <ul class="nhsuk-list">
                    <% session.dates.each do |date| %>
                      <li><%= date.to_fs(:long) %></li>
                    <% end %>
                  </ul>
                <% end %>

                <% row.with_cell do %>
                  <% if @programme_type.nil? %>
                    <span class="nhsuk-table-responsive__heading">Programme</span>
                    <%= render AppProgrammeTagsComponent.new([programme]) %>
                  <% else %>
                    <span class="nhsuk-table-responsive__heading">Session outcome</span>
                    <%= '?' %>
                  <% end %>
                <% end %>
              <% end %>
            <% end %>
          <% end %>
        <% end %>
      <% end %>
    <% else %>
      <p class="nhsuk-body">No sessions</p>
    <% end %>
  ERB

  def initialize(patient, current_team:, programme_type: nil)
    @patient = patient
    @current_team = current_team
    @programme_type = programme_type
  end

  private

  attr_reader :patient, :current_team, :programme_type

  delegate :govuk_table, to: :helpers

  def sessions
    @sessions ||=
      patient
        .sessions
        .for_team(current_team)
        .then { |sessions|
          if @programme_type
            sessions.has_any_programme_types_of(programme_type)
          else
            sessions
          end
        }
        .includes(:location, :session_programme_year_groups)
  end
end
