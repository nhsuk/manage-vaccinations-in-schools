# frozen_string_literal: true

class AppHealthAnswersCardComponent < ViewComponent::Base
  def initialize(objects, heading: "Answers to health questions")
    super

    @objects = objects.is_a?(Array) ? objects : [objects]
    @heading = heading
  end

  def call
    render AppCardComponent.new(heading_level: 2) do |card|
      card.with_heading { heading }
      render AppHealthAnswersSummaryComponent.new(objects)
    end
  end

  private

  attr_reader :objects, :heading
end
