class AppHealthQuestionsComponent < ViewComponent::Base
  erb_template <<-ERB
    <% health_questions.each do |health_question| %>
      <h3 class="nhsuk-heading-xs nhsuk-u-margin-bottom-0">
        <%= health_question[:question] %>
      </h3>
      <p><%= safe_join(health_question[:answers], tag.br) %></p>
    <% end %>
  ERB

  def initialize(consents:)
    super

    @consents = consents
  end

  def health_questions
    # Generates a hash like:
    # {
    #   "First question?" => {
    #     "Mum" => "No",
    #     "Dad" => "No"
    #   },
    #   "Second question?" => {
    #     "Mum" => "No",
    #     "Dad" =>" Yes – Notes"
    #   }
    # }
    dict =
      @consents.each_with_object({}) do |consent, acc|
        consent.health_questions.each do |health_question|
          question = health_question["question"]
          response = health_question["response"]
          notes = health_question["notes"]

          formatted_answer = response.humanize
          formatted_answer += " – #{notes}" if notes.present?

          acc[question] ||= {}
          acc[question][consent.who_responded] = formatted_answer
        end
      end

    # Generates an array of hashes like:
    # [
    #   {
    #     "question" => "First question?",
    #     "answer" => ["All responded: No"]
    #   }
    #   {
    #     "question" => "Second question?",
    #     "answer" => ["Mum responded: No", "Dad responded: Yes – Notes"]}
    #   }
    # }
    dict.map do |question, answers|
      only_one_consent = @consents.length == 1
      answers_are_all_identical =
        @consents.length == answers.length && answers.values.uniq.length == 1

      formatted_answers =
        if only_one_consent
          [answers.values.first]
        elsif answers_are_all_identical
          ["All responded: #{answers.values.first}"]
        else
          answers.map { |who, response| "#{who} responded: #{response}" }
        end

      { question:, answers: formatted_answers }
    end
  end
end
