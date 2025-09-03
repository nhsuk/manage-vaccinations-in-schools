# frozen_string_literal: true

class AppNoticesTableComponent < ViewComponent::Base
  def initialize(notices)
    @notices = notices
  end

  private

  attr_reader :notices

  delegate :govuk_table, to: :helpers
end
