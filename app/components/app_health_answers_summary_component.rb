# frozen_string_literal: true

class AppHealthAnswersSummaryComponent < ViewComponent::Base
  erb_template <<-ERB
    <dl class="nhsuk-summary-list app-summary-list--full-width">
      <% health_answers.each do |question, answers| %>
        <div class="nhsuk-summary-list__row">
          <dt class="nhsuk-summary-list__key">
            <%= question %>
          </dt>
          <dd class="nhsuk-summary-list__value">
            <% answers.each do |answer| %>
              <p>
                <%= answer[:responder] %> responded: <%= answer[:answer].humanize %><% if answer[:notes].present? %>:<% end %>
              </p>
              <% if answer[:notes].present? %>
                <blockquote><%= answer[:notes] %></blockquote>
              <% end %>
            <% end %>
          </dd>
        </div>
      <% end %>
    </dl>
  ERB

  def initialize(objects)
    @objects = objects.is_a?(Array) ? objects : [objects]
  end

  private

  attr_reader :objects

  def health_answers
    ConsolidatedHealthAnswers.new(objects).to_h
  end
end
