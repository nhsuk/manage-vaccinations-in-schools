# frozen_string_literal: true

class AppConsentRefusedTableComponent < ViewComponent::Base
  def initialize(consents, vaccine_may_contain_gelatine:)
    @grouped_by_reason_for_refusal =
      consents.response_refused.group(:reason_for_refusal).count
    @total_count = @grouped_by_reason_for_refusal.values.sum
    @vaccine_may_contain_gelatine = vaccine_may_contain_gelatine
  end

  private

  attr_reader :grouped_by_reason_for_refusal,
              :total_count,
              :vaccine_may_contain_gelatine

  delegate :govuk_table, to: :helpers

  def percentage_for(reason_for_refusal)
    return 0 if total_count.zero?

    grouped_by_reason_for_refusal.fetch(reason_for_refusal, 0) /
      total_count.to_f * 100.0
  end

  def reasons_for_refusal
    reasons = Consent.reason_for_refusals.keys
    reasons -= %w[contains_gelatine] unless vaccine_may_contain_gelatine
    reasons
  end
end
