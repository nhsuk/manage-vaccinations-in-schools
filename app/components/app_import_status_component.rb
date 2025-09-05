# frozen_string_literal: true

class AppImportStatusComponent < ViewComponent::Base
  def initialize(import:, break_tag: false)
    @import = import
    @break_tag = break_tag
  end

  private

  delegate :govuk_tag, to: :helpers

  def status_text
    {
      "pending_import" => "Processing",
      "rows_are_invalid" => "Invalid",
      "processed" => "Completed"
    }.fetch(@import.status)
  end

  def status_color
    {
      "pending_import" => "blue",
      "rows_are_invalid" => "red",
      "processed" => "green"
    }.fetch(@import.status)
  end
end
