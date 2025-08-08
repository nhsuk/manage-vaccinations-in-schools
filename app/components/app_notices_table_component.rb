# frozen_string_literal: true

class AppNoticesTableComponent < ViewComponent::Base
  def initialize(notices)
    super

    @notices = notices
  end

  private

  attr_reader :notices
end
