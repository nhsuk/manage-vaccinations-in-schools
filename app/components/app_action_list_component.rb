# frozen_string_literal: true

class AppActionListComponent < ViewComponent::Base
  renders_many :items, "Item"

  erb_template <<~ERB
    <% if items? %>
      <ul class="app-action-list">
        <% items.each do |item| %>
          <li class="app-action-list__item"><%= item %></li>
        <% end %>
      </ul>
    <% end %>
  ERB

  class Item < ViewComponent::Base
    def initialize(text: nil, href: nil)
      @text = html_escape(text)
      @href = href
    end

    def call
      if @href.present?
        link_to(content || @text, @href)
      elsif @text.present?
        @text
      else
        content || raise(ArgumentError, "no text or content")
      end
    end
  end
end
