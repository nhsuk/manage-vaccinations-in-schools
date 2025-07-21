# frozen_string_literal: true

class AppLogEventComponent < ViewComponent::Base
  erb_template <<-ERB
    <% if card %>
      <div class="nhsuk-card"><div class="nhsuk-card__content">
    <% end %>

    <% if title.present? %>
      <h4 class="<% if card %>nhsuk-card__heading <% end %>nhsuk-heading-s">
        <%= invalidated ? tag.s(title) : title %>
      </h4>
    <% end %>

    <% if body.present? %>
      <blockquote><p>
        <%= invalidated ? tag.s(body) : body %>
      </p></blockquote>
    <% end %>

    <p class="nhsuk-body-s nhsuk-u-margin-0 nhsuk-u-secondary-text-color">
      <% if programmes.any? %>
        <%= render AppProgrammeTagsComponent.new(programmes) %>
        &nbsp;
      <% end %>
      <%= invalidated ? tag.s(subtitle) : subtitle %>
    </p>

    <% if card %>
      </div></div>
    <% end %>
  ERB

  def initialize(
    title: nil,
    at: nil,
    body: nil,
    by: nil,
    programmes: [],
    invalidated: false,
    card: false
  )
    super

    @title = title
    @body = body
    @at = at.to_fs(:long)
    @by = by.respond_to?(:full_name) ? by.full_name : by
    @programmes = programmes
    @invalidated = invalidated
    @card = card
  end

  private

  attr_reader :title, :body, :programmes, :invalidated, :card

  def subtitle
    safe_join([@at, @by].compact, " &middot; ".html_safe)
  end
end
