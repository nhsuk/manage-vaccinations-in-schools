# frozen_string_literal: true

class AppSessionSearchFormComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= form_with url:, method: :get, builder: GOVUKDesignSystemFormBuilder::FormBuilder do |f| %>
      <%= render AppCardComponent.new(heading_level: 2, filters: true) do |card| %>
        <% card.with_heading { "Find session" } %>

        <div class="app-search-input" role="search">
          <%= f.govuk_text_field :q,
                                 value: form.q,
                                 label: { text: "Search", class: "nhsuk-u-visually-hidden" },
                                 autocomplete: "off",
                                 class: "app-search-input__input" %>

          <button class="nhsuk-button app-button--icon app-search-input__submit" data-module="nhsuk-button" type="submit">
            <svg class="nhsuk-icon nhsuk-icon__search" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" focusable="false" role="img">
              <title>Search</title>
              <path d="M19.71 18.29l-4.11-4.1a7 7 0 1 0-1.41 1.41l4.1 4.11a1 1 0 0 0 1.42 0 1 1 0 0 0 0-1.42zM5 10a5 5 0 1 1 5 5 5 5 0 0 1-5-5z" fill="currentColor"></path>
            </svg>
          </button>
        </div>

        <% if programmes.present? %>
          <%= f.govuk_check_boxes_fieldset :programmes, legend: { text: "Programme", size: "s" } do %>
            <% programmes.each do |programme| %>
              <%= f.govuk_check_box :programmes,
                                    programme.type,
                                    checked: form.programmes&.include?(programme.type),
                                    label: { text: programme.name } %>
            <% end %>
          <% end %>
        <% end %>

        <% if academic_years && AcademicYear.pending != AcademicYear.current %>
          <%= f.govuk_radio_buttons_fieldset :academic_year, legend: { text: "Academic year", size: "s" } do %>
            <% [AcademicYear.pending, AcademicYear.current].each do |academic_year| %>
              <%= f.govuk_radio_button :academic_year,
                                       academic_year,
                                       checked: form.academic_year == academic_year,
                                       label: { text: helpers.format_academic_year(academic_year) } %>
            <% end %>
          <% end %>
        <% end %>

        <%= f.govuk_radio_buttons_fieldset :status, legend: { text: "Status", size: "s" } do %>
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
        
        <%= f.govuk_radio_buttons_fieldset :type, legend: { text: "Type", size: "s" } do %>
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

        <div class="app-button-group">
          <%= f.govuk_submit "Update results", secondary: true, class: "app-button--small" %>
          <%= govuk_button_link_to "Clear filters", clear_filters_path, secondary: true, class: "app-button--small" %>
        </div>
      <% end %>
    <% end %>
  ERB

  def initialize(form, url:, programmes:, academic_years:)
    super

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

  def clear_filters_path = "#{@url}?_clear=true"
end
