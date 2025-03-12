# frozen_string_literal: true

class AppRegisterStatusTagComponent < ViewComponent::Base
  def initialize(status)
    super

    @status = status
  end

  def call = govuk_tag(text:, colour:)

  private

  def text
    I18n.t(@status, scope: %i[status register label])
  end

  def colour
    I18n.t(@status, scope: %i[status register colour])
  end
end
