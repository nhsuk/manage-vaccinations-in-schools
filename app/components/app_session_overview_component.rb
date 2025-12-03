# frozen_string_literal: true

class AppSessionOverviewComponent < ViewComponent::Base
  def initialize(session)
    @session = session
  end

  private

  attr_reader :session
end
