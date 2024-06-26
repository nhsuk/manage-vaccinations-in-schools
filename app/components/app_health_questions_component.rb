# frozen_string_literal: true

class AppHealthQuestionsComponent < ViewComponent::Base
  erb_template <<-ERB
    <dl class="nhsuk-summary-list app-summary-list--full-width nhsuk-u-margin-bottom-0">
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

  def initialize(consents:)
    super

    @consents = consents
  end

  def health_answers
    consolidated_answers = ConsolidatedHealthAnswers.new

    @consents.each do |consent|
      consent.health_answers.each do |health_question|
        consolidated_answers.add_answer(
          responder: consent.who_responded,
          question: health_question.question,
          answer: health_question.response.humanize.presence,
          notes: health_question.notes.presence
        )
      end
    end

    consolidated_answers.to_h
  end
end
