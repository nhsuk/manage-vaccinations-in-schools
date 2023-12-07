class AppHealthQuestionsComponent < ViewComponent::Base
  erb_template <<-ERB
    <% health_questions.each do |health_question| %>
      <h3 class="nhsuk-heading-xs nhsuk-u-margin-bottom-0">
        <%= health_question["question"] %>
      </h3>
      <% if health_question["response"].downcase == "yes" %>
        <p>
          <%= health_question["response"].humanize %> &ndash;
          <%= health_question["notes"] %>
        </p>
      <% else %>
        <p><%= health_question["response"].humanize %></p>
      <% end %>
    <% end %>
  ERB

  def initialize(consents:)
    super

    # HACK: This needs to work with multiple consents
    @consent = consents.first
  end

  def health_questions
    @consent&.health_questions
  end
end
