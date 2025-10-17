# frozen_string_literal: true

class AppSessionSearchFormComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= form_with url:, method: :get, builder: GOVUKDesignSystemFormBuilder::FormBuilder do |f| %>
      <%= render AppCardComponent.new(filters: true) do |card| %>
        <% card.with_heading(level: 2) { "Find session" } %>

        <div class="app-search-input" role="search">
          <%= f.govuk_text_field :q,
                                 value: form.q,
                                 label: { text: "Search", class: "nhsuk-u-visually-hidden" },
                                 autocomplete: "off",
                                 class: "app-search-input__input" %>

          <button class="nhsuk-button app-button--icon app-search-input__submit" data-module="nhsuk-button" type="submit">
            <svg class="nhsuk-icon nhsuk-icon--search" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="16" height="16" focusable="false" role="img" aria-label="Search">
              <title>Search</title>
              <path d="m20.7 19.3-4.1-4.1a7 7 0 1 0-1.4 1.4l4 4.1a1 1 0 0 0 1.5 0c.4-.4.4-1 0-1.4ZM6 11a5 5 0 1 1 10 0 5 5 0 0 1-10 0Z"/>
            </svg>
          </button>
        </div>

        <% if programmes.present? %>
          <%= f.govuk_check_boxes_fieldset :programmes,
                                           legend: { text: "Programme", size: "s" },
                                           small: true do %>
            <% programmes.each do |programme| %>
              <%= f.govuk_check_box :programmes,
                                    programme.type,
                                    checked: form.programmes&.include?(programme.type),
                                    label: { text: programme.name } %>
            <% end %>
          <% end %>
        <% end %>

        <% if academic_years && AcademicYear.pending != AcademicYear.current %>
          <%= f.govuk_radio_buttons_fieldset :academic_year,
                                             legend: { text: "Academic year", size: "s" },
                                             small: true do %>
            <% [AcademicYear.pending, AcademicYear.current].each do |academic_year| %>
              <%= f.govuk_radio_button :academic_year,
                                       academic_year,
                                       checked: form.academic_year == academic_year,
                                       label: { text: helpers.format_academic_year(academic_year) } %>
            <% end %>
          <% end %>
        <% end %>

        <%= f.govuk_radio_buttons_fieldset :status,
                                           legend: { text: "Status", size: "s" },
                                           small: true do %>
          <%= f.govuk_radio_button :status, "",
                                   checked: form.status.blank?,
                                   label: { text: "Any" } %>

          <% STATUSES.each do |value| %>
            <%= f.govuk_radio_button :status,
                                     value,
                                     checked: form.status == value,
                                     label: { text: value.humanize } %>
          <% end %>
        <% end %>
        
        <%= f.govuk_radio_buttons_fieldset :type,
                                           legend: { text: "Type", size: "s" },
                                           small: true do %>
          <%= f.govuk_radio_button :type, "",
                                   checked: form.type.blank?,
                                   label: { text: "Any" } %>

          <% TYPES.each do |value, label| %>
            <%= f.govuk_radio_button :type,
                                     value,
                                     checked: form.type == value,
                                     label: { text: label } %>
          <% end %>
        <% end %>

        <div class="nhsuk-button-group">
          <%= f.govuk_submit "Update results", secondary: true, class: "app-button--small" %>
          <%= govuk_button_link_to "Clear filters", clear_filters_path, secondary: true, class: "app-button--small" %>
        </div>
      <% end %>
    <% end %>
  ERB

  def initialize(form, url:, programmes:, academic_years:)
    @form = form
    @url = url
    @programmes = programmes
    @academic_years = academic_years
  end

  private

  STATUSES = %w[in_progress unscheduled scheduled completed].freeze

  TYPES = {
    "school" => "School session",
    "generic_clinic" => "Community clinic"
  }.freeze

  attr_reader :form, :url, :programmes, :academic_years

  delegate :govuk_button_link_to, to: :helpers

  def clear_filters_path = "#{@url}?_clear=true"
end
