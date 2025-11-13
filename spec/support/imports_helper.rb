# frozen_string_literal: true

module ImportsHelper
  def wait_for_import_to_complete(import_class)
    perform_enqueued_jobs(only: ProcessImportJob)

    perform_enqueued_jobs_while_exists(only: PDSCascadingSearchJob)
    perform_enqueued_jobs_while_exists(only: ProcessPatientChangesetJob)

    CommitImportJob.drain
    click_on_most_recent_import(import_class)
  end

  def click_on_most_recent_import(import_class)
    click_on import_class.order(:created_at).last.created_at.to_fs(:long),
             match: :first
  end

  def perform_enqueued_jobs_while_exists(only:)
    job_class = only.name

    # rubocop:disable Style/WhileUntilModifier
    while enqueued_jobs.any? { it["job_class"] == job_class }
      perform_enqueued_jobs(only:)
    end
    # rubocop:enable Style/WhileUntilModifier
  end
end
