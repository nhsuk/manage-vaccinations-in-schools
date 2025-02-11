# frozen_string_literal: true

#   GoodJob::Execution.prepend(
#     GoodJobExecutionPatch
#   )
#
require "good_job"

module GoodJobExecutionPatch
  def get_batch(batch = nil, since: 1.hour.ago)
    where("finished_at > ?", since).select do
      batch.nil? || it.serialized_params["arguments"][0]["batch"] == batch
    end
  end

  def batch_stats(batch = nil, since: 1.hour.ago)
    get_batch(batch, since:)
      .group_by { it.finished_at.change(usec: 0) }
      .transform_values do |executions|
        { total: executions.count }.tap do |stats|
          stats[:avg_duration] = executions.sum(&:duration) / stats[:total]
          executions
            .partition { it.error.nil? }
            .tap do |successs, errors|
              stats.merge! successes: successs.count, errors: errors.pluck(:id)
            end
        end
      end
      .sort_by(&:first)
  end

  def batch_count(batch = nil, since: 1.hour.ago)
    get_batch(batch, since:).count
  end
end

GoodJob::Execution.extend(GoodJobExecutionPatch)
