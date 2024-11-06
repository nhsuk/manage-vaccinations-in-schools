# frozen_string_literal: true

class AppConsentRefusedTableComponent < ViewComponent::Base
  def initialize(consents)
    super

    @grouped_by_reason_for_refusal =
      consents.response_refused.group(:reason_for_refusal).count
    @total_count = @grouped_by_reason_for_refusal.values.sum
  end

  def percentage_for(reason_for_refusal)
    return 0 if @total_count.zero?

    @grouped_by_reason_for_refusal.fetch(reason_for_refusal, 0) /
      @total_count.to_f * 100.0
  end
end
