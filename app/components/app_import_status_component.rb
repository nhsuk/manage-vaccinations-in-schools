# frozen_string_literal: true

class AppImportStatusComponent < ViewComponent::Base
  def initialize(import:, break_tag: false)
    super
    @import = import
    @break_tag = break_tag
  end

  private

  def status_text
    {
      "pending_import" => "Processing",
      "rows_are_invalid" => "Invalid",
      "recorded" => "Completed"
    }[
      @import.status
    ]
  end

  def status_color
    {
      "pending_import" => "blue",
      "rows_are_invalid" => "red",
      "recorded" => "green"
    }[
      @import.status
    ]
  end
end
