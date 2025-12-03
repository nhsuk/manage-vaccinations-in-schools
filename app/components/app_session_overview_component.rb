# frozen_string_literal: true

class AppSessionOverviewComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppSessionStatsComponent.new(session) %>

    <section>
      <%= render AppSessionVaccinationsComponent.new(session) %>
    </section>

    <section>
      <%= render AppSessionActionsComponent.new(session) %>
    </section>

    <section>
      <%= render AppSessionDetailsComponent.new(session) %>
    </section>

    <section>
      <%= render AppSessionButtonsComponent.new(session) %>
    </section>
  ERB

  def initialize(session)
    @session = session
  end

  private

  attr_reader :session
end
