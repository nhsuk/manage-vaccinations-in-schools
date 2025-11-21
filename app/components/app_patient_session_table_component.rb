# frozen_string_literal: true

class AppPatientSessionTableComponent < ViewComponent::Base
  erb_template <<-ERB
    <% if sessions.any? %>
      <%= govuk_table(html_attributes: { class: "nhsuk-table-responsive" }) do |table| %>
        <% table.with_head do |head| %>
          <% head.with_row do |row| %>
            <% row.with_cell(text: "Location") %>
            <% row.with_cell(text: "Session dates") %>
            <% row.with_cell(text: "Programme") %>
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
                  <span class="nhsuk-table-responsive__heading">Programme</span>
                  <%= render AppProgrammeTagsComponent.new([programme]) %>
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

  def initialize(patient, current_team:)
    @patient = patient
    @current_team = current_team
  end

  private

  attr_reader :patient, :current_team

  delegate :govuk_table, to: :helpers

  def sessions
    @sessions ||= patient.sessions.where(team: current_team).includes(:location)
  end
end
