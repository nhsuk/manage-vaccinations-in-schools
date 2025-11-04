# frozen_string_literal: true

class HealthAnswer
  include ActiveModel::Model

  include Notable

  attr_accessor :id,
                :question,
                :response,
                :notes,
                :hint,
                :next_question,
                :follow_up_question,
                :would_require_triage,
                :give_details_hint

  validates :response, inclusion: { in: %w[yes no] }

  def attributes
    %i[
      id
      question
      response
      notes
      hint
      next_question
      follow_up_question
      would_require_triage
      give_details_hint
    ].index_with { |attr| send(attr) }
  end

  def next_health_answer_index
    response_no? ? next_question : follow_up_question || next_question
  end

  def assign_attributes(attrs)
    attrs = attrs.except("notes") if attrs["response"] == "no"
    super(attrs)
  end

  ANY_OTHER_MEDICAL_CONDITIONS_QUESTION =
    "Does your child have any other medical conditions the immunisation team should be aware of?"

  def would_require_triage?(team_id:)
    # TODO: This is a quick fix to resolve an incident with the intention
    #  to design a long term solution to this problem. Specifically, we know
    #  that some teams don't want this question to triage, but some do.
    #  https://nhsd-jira.digital.nhs.uk/browse/MAV-2480

    if team_id == HealthAnswer.leicestershire_team_id &&
         question == ANY_OTHER_MEDICAL_CONDITIONS_QUESTION
      return true
    end

    # `nil` to support historical health answers without this attribute
    [nil, true].include?(would_require_triage)
  end

  def self.leicestershire_team_id
    return @leicestershire_team_id if defined?(@leicestershire_team_id)
    @leicestershire_team_id = Team.find_by(workgroup: "leicestershiresais")&.id
  end

  def ask_notes? = follow_up_question.nil?

  def requires_notes? = ask_notes? && response_yes?

  def response_yes? = response == "yes"

  def response_no? = response == "no"

  def self.from_health_questions(health_questions)
    hq_id_map = Hash[health_questions.map.with_index { |hq, i| [hq.id, i] }]

    health_questions.map do |hq|
      new(
        id: hq_id_map[hq.id],
        question: hq.title,
        response: nil,
        notes: nil,
        hint: hq.hint,
        next_question: hq_id_map[hq.next_question_id],
        follow_up_question: hq_id_map[hq.follow_up_question_id],
        would_require_triage: hq.would_require_triage,
        give_details_hint: hq.give_details_hint
      )
    end
  end

  class ArraySerializer
    def self.load(arr)
      return if arr.nil?
      arr.map.with_index do |(item), idx|
        HealthAnswer.new(
          item.merge("id" => idx).except("context_for_validation", "errors")
        )
      end
    end

    def self.dump(values)
      values.map { |value| value.is_a?(Hash) ? value : value.attributes }
    end
  end
end
