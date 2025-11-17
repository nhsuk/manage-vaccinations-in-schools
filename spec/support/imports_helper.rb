# frozen_string_literal: true

module ImportsHelper
  def wait_for_import_to_complete(import_class)
    wait_for_import_to_complete_until_review(import_class)

    if page.has_button?("Approve and import records")
      click_on "Approve and import records"
    end

    wait_for_import_to_commit(import_class)
  end

  def wait_for_import_to_commit(import_class)
    CommitPatientChangesetsJob.drain
    CommitImportJob.drain
    click_on_most_recent_import(import_class)
  end

  def wait_for_import_to_complete_until_review(import_class)
    perform_enqueued_jobs(only: ProcessImportJob)

    perform_enqueued_jobs_while_exists(only: PDSCascadingSearchJob)
    perform_enqueued_jobs_while_exists(only: ProcessPatientChangesetJob)
    perform_enqueued_jobs_while_exists(only: ReviewPatientChangesetJob)
    perform_enqueued_jobs(only: ReviewClassImportSchoolMoveJob)

    if Flipper.enabled?(:import_review_screen)
      click_on_most_recent_import(import_class)
    end
  end

  def click_on_most_recent_import(import_class)
    link_text = import_class.order(:created_at).last.created_at.to_fs(:long)
    click_on link_text, match: :first if page.has_link?(link_text)
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
