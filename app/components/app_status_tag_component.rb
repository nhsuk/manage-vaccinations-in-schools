# frozen_string_literal: true

class AppStatusTagComponent < ViewComponent::Base
  def initialize(status, context:)
    @status = status
    @context = context
  end

  def call = tag.strong(text, class: ["nhsuk-tag nhsuk-tag--#{colour}"])

  private

  def text
    I18n.t(@status, scope: [:status, @context, :label])
  end

  def colour
    I18n.t(@status, scope: [:status, @context, :colour])
  end
end
