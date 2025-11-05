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
      "in_review" => "Needs review",
      "calculating_re_review" => "Processing",
      "in_re_review" => "Needs re-review",
      "processed" => "Completed",
      "low_pds_match_rate" => "Failed"
    }.fetch(@import.status)
  end

  def status_color
    {
      "pending_import" => "blue",
      "rows_are_invalid" => "red",
      "changesets_are_invalid" => "red",
      "in_review" => "yellow",
      "calculating_re_review" => "blue",
      "in_re_review" => "yellow",
      "processed" => "green",
      "low_pds_match_rate" => "red"
    }.fetch(@import.status)
  end
end
