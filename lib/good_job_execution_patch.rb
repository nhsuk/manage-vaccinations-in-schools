# frozen_string_literal: true

#   GoodJob::Execution.prepend(
#     GoodJobExecutionPatch
#   )
#
require "good_job"

module GoodJobExecutionPatch
  def run_stats(since: 1.hour.ago, batch: nil)
    where("finished_at > ?", since)
      .select do
        batch.nil? || it.serialized_params["arguments"][0]["batch"] == batch
      end
      .group_by { it.finished_at.change(usec: 0) }
      .transform_values do |executions|
        { total: executions.count }.tap do
          errors = executions.select { _1.error.present? }
          it.merge!(errors: errors.count) if errors.any?
        end
      end
      .sort_by(&:first)
  end
end

GoodJob::Execution.extend(GoodJobExecutionPatch)
