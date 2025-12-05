# frozen_string_literal: true

class AppSessionButtonsComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="nhsuk-button-group">
      <% if policy(session).edit? %>
        <%= govuk_button_link_to "Edit session", edit_session_path(session), secondary: true %>

        <%= link_to "Record offline", session_path(session, format: :xlsx) %>

        <% if session.clinic? && session.can_send_clinic_invitations? %>
          <%= link_to "Send booking reminders", edit_session_invite_to_clinic_path(@session) %>
        <% elsif session.school? && session.can_send_clinic_invitations? %>
          <%= link_to "Send clinic invitations", edit_session_invite_to_clinic_path(@session) %>
        <% end %>
      <% end %>
    </div>
  ERB

  def initialize(session)
    @session = session
  end

  private

  attr_reader :session

  delegate :policy, :govuk_button_link_to, to: :helpers
end
