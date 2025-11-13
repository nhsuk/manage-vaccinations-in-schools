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
      "changesets_are_invalid" => "Failed",
      "processed" => "Completed",
      "low_pds_match_rate" => "Failed"
    }.fetch(@import.status)
  end

  def status_color
    {
      "pending_import" => "blue",
      "rows_are_invalid" => "red",
      "changesets_are_invalid" => "red",
      "processed" => "green",
      "low_pds_match_rate" => "red"
    }.fetch(@import.status)
  end
end
