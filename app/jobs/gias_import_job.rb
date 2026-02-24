# frozen_string_literal: true

class GIASImportJob < ApplicationJob
  include SingleConcurrencyConcern

  queue_as :third_party_data_imports

  def perform(dry_run: false)
    tx_id = SecureRandom.urlsafe_base64(16)

    SemanticLogger.tagged(tx_id:, job_id:) do
      Sentry.set_tags(tx_id:, job_id:)

      GIAS.download
      GIAS.check_import
      GIAS.import unless dry_run
    end
  end
end
