# frozen_string_literal: true

module ImportsHelper
  def wait_for_import_to_complete(import_class)
    perform_enqueued_jobs(only: ProcessImportJob)

    wait_for_jobs_to_finish("PDSCascadingSearchJob")
    wait_for_jobs_to_finish("ProcessPatientChangesetJob")

    perform_enqueued_jobs(only: CommitPatientChangesetsJob)
    click_on_most_recent_import(import_class)
  end

  def click_on_most_recent_import(import_class)
    click_on import_class.order(:created_at).last.created_at.to_fs(:long),
             match: :first
  end

  def wait_for_jobs_to_finish(job_class)
    # rubocop:disable Style/WhileUntilModifier
    while enqueued_jobs.any? { it["job_class"] == job_class }
      perform_enqueued_jobs(only: job_class.constantize)
    end
    # rubocop:enable Style/WhileUntilModifier
  end
end
