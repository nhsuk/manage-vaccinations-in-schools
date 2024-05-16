class AppHealthQuestionsComponent < ViewComponent::Base
  erb_template <<-ERB
    <dl class="nhsuk-summary-list app-summary-list--full-width">
      <% health_answers.each do |health_question| %>
        <div class="nhsuk-summary-list__row">
          <dt class="nhsuk-summary-list__key">
            <%= health_question[:question] %>
          </dt>
          <dd class="nhsuk-summary-list__value">
            <p><%= safe_join(health_question[:answers], tag.br) %></p>
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
          answer: health_question.response,
          notes: health_question.notes
        )
      end
    end

    consolidated_answers.to_h.map do |question, answers|
      { question:, answers: answers.map { |answer| answer_string(answer) } }
    end
  end

  def answer_string(answer)
    responder_string =
      @consents.size > 1 ? "#{answer[:responder]} responded: " : ""
    notes_string = answer[:notes].present? ? " – #{answer[:notes]}" : ""

    "#{responder_string}#{answer[:answer].humanize}#{notes_string}"
  end
end
