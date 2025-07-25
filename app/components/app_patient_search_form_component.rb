# frozen_string_literal: true

class AppPatientSearchFormComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= form_with url:, method: :get, builder: GOVUKDesignSystemFormBuilder::FormBuilder do |f| %>
      <%= render AppCardComponent.new(heading_level:, filters: true) do |card| %>
        <% card.with_heading { "Find children" } %>

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
        
        <% if programmes.size > 1 %>
          <%= f.govuk_check_boxes_fieldset :programme_types, legend: { text: "Programme", size: "s" } do %>
            <% programmes.each do |programme| %>
              <%= f.govuk_check_box :programme_types,
                                    programme.type,
                                    checked: form.programme_types&.include?(programme.type),
                                    label: { text: programme.name } %>
            <% end %>
          <% end %>
        <% end %>

        <% if consent_statuses.any? %>
          <%= f.govuk_check_boxes_fieldset :consent_statuses, legend: { text: "Consent status", size: "s" } do %>
            <% consent_statuses.each do |status| %>
              <%= f.govuk_check_box :consent_statuses,
                                    status,
                                    checked: form.consent_statuses&.include?(status),
                                    label: { text: t(status, scope: %i[status consent label]) } %>
            <% end %>
          <% end %>
        <% end %>

        <% if triage_statuses.any? %>
          <%= f.govuk_radio_buttons_fieldset :triage_status, legend: { text: "Triage status", size: "s" } do %>
            <%= f.govuk_radio_button :triage_status, "", checked: form.triage_status.blank?, label: { text: "Any" } %>
            <% triage_statuses.each do |status| %>
              <%= f.govuk_radio_button :triage_status,
                                       status,
                                       checked: form.triage_status == status,
                                       label: { text: t(status, scope: %i[status triage label]) } %>
            <% end %>
          <% end %>
        <% end %>

        <% if register_statuses.any? %>
          <%= f.govuk_radio_buttons_fieldset :register_status, legend: { text: "Registration status", size: "s" } do %>
            <%= f.govuk_radio_button :register_status, "", checked: form.register_status.blank?, label: { text: "Any" } %>
            <% register_statuses.each do |status| %>
              <%= f.govuk_radio_button :register_status,
                                       status,
                                       checked: form.register_status == status,
                                       label: { text: t(status, scope: %i[status register label]) } %>
            <% end %>
          <% end %>
        <% end %>

        <% if session_statuses.any? %>
          <%= f.govuk_radio_buttons_fieldset :session_status, legend: { text: "Session outcome", size: "s" } do %>
            <%= f.govuk_radio_button :session_status, "", checked: form.session_status.blank?, label: { text: "Any" } %>
            <% session_statuses.each do |status| %>
              <%= f.govuk_radio_button :session_status,
                                       status,
                                       checked: form.session_status == status,
                                       label: { text: t(status, scope: %i[status session label]) } %>
            <% end %>
          <% end %>
        <% end %>

        <% if programme_statuses.any? %>
          <%= f.govuk_radio_buttons_fieldset :programme_status, legend: { text: "Programme outcome", size: "s" } do %>
            <%= f.govuk_radio_button :programme_status, "", checked: form.programme_status.blank?, label: { text: "Any" } %>

            <% programme_statuses.each do |status| %>
              <%= f.govuk_radio_button :programme_status,
                                       status,
                                       checked: form.programme_status == status,
                                       label: { text: t(status, scope: %i[status programme label]) } %>
            <% end %>
          <% end %>
        <% end %>

        <% if vaccine_methods.any? %>
          <%= f.govuk_radio_buttons_fieldset :vaccine_method, legend: { text: "Vaccination method", size: "s" } do %>
            <%= f.govuk_radio_button :vaccine_method, "", checked: form.vaccine_method.blank?, label: { text: "Any" } %>

            <% vaccine_methods.each do |vaccine_method| %>
              <%= f.govuk_radio_button :vaccine_method,
                                       vaccine_method,
                                       checked: form.vaccine_method == vaccine_method,
                                       label: { text: Vaccine.human_enum_name(:vaccine_method, vaccine_method) } %>
            <% end %>
          <% end %>
        <% end %>

        <% if year_groups.any? %>
          <%= f.govuk_check_boxes_fieldset :year_groups, legend: { text: "Year group", size: "s" } do %>
            <% year_groups.each do |year_group| %>
              <%= f.govuk_check_box :year_groups,
                                    year_group,
                                    checked: form.year_groups&.include?(year_group),
                                    label: { text: helpers.format_year_group(year_group) } %>
            <% end %>
          <% end %>
        <% end %>

        <%= govuk_details(summary_text: "Advanced filters", open: open_details?) do %>
          <div class="nhsuk-form-group">
            <fieldset class="nhsuk-fieldset">
              <legend class="nhsuk-fieldset__legend nhsuk-fieldset__legend--s">Date of birth</legend>
              <div class="nhsuk-date-input">
                <div class="nhsuk-date-input__item">
                  <%= f.govuk_number_field :date_of_birth_day,
                                           value: form.date_of_birth_day,
                                           label: { text: "Day" },
                                           width: 2 %>
                </div>
                <div class="nhsuk-date-input__item">
                  <%= f.govuk_number_field :date_of_birth_month,
                                           value: form.date_of_birth_month,
                                           label: { text: "Month" },
                                           width: 2 %>
                </div>
                <div class="nhsuk-date-input__item">
                  <%= f.govuk_number_field :date_of_birth_year,
                                           value: form.date_of_birth_year,
                                           label: { text: "Year" },
                                           width: 4 %>
                </div>
              </div>
            </fieldset>
          </div>

          <%= f.govuk_check_boxes_fieldset :missing_nhs_number, multiple: false, legend: { text: "Options", size: "s" } do %>
            <%= f.govuk_check_box :missing_nhs_number,
                                  1, 0,
                                  checked: form.missing_nhs_number,
                                  multiple: false,
                                  link_errors: true,
                                  label: { text: "Missing NHS number" } %>
          <% end %>

          <% if show_buttons_in_details? %>
            <div class="app-button-group">
              <%= f.govuk_submit "Update results", secondary: true, class: "app-button--small" %>
              <%= govuk_button_link_to "Clear filters", clear_filters_path, secondary: true, class: "app-button--small" %>
            </div>
          <% end %>
        <% end %>

        <% unless show_buttons_in_details? %>
          <div class="app-button-group">
            <%= f.govuk_submit "Update results", secondary: true, class: "app-button--small" %>
            <%= govuk_button_link_to "Clear filters", clear_filters_path, secondary: true, class: "app-button--small" %>
          </div>
        <% end %>
      <% end %>
    <% end %>
  ERB

  def initialize(
    form,
    url:,
    programmes: [],
    consent_statuses: [],
    programme_statuses: [],
    register_statuses: [],
    session_statuses: [],
    triage_statuses: [],
    vaccine_methods: [],
    year_groups: [],
    heading_level: 3
  )
    super

    @form = form
    @url = url

    @programmes = programmes
    @consent_statuses = consent_statuses
    @programme_statuses = programme_statuses
    @register_statuses = register_statuses
    @session_statuses = session_statuses
    @triage_statuses = triage_statuses
    @vaccine_methods = vaccine_methods
    @year_groups = year_groups
    @heading_level = heading_level
  end

  private

  attr_reader :form,
              :url,
              :programmes,
              :consent_statuses,
              :programme_statuses,
              :register_statuses,
              :session_statuses,
              :triage_statuses,
              :vaccine_methods,
              :year_groups,
              :heading_level

  def open_details?
    @form.date_of_birth_year.present? || @form.date_of_birth_month.present? ||
      @form.date_of_birth_day.present? || @form.missing_nhs_number
  end

  def show_buttons_in_details?
    !(
      consent_statuses.any? || programme_statuses.any? ||
        register_statuses.any? || session_statuses.any? ||
        triage_statuses.any? || year_groups.any?
    )
  end

  def clear_filters_path = "#{@url}?_clear=true"
end
