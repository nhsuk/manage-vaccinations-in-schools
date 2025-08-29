# frozen_string_literal: true

module ImportsHelper
  def wait_for_import_to_complete(import_class)
    perform_enqueued_jobs(only: ProcessImportJob)

    # rubocop:disable Style/BlockDelimiters
    while enqueued_jobs.any? {
            it["job_class"] == "ProcessPatientChangesetsJob"
          }
      perform_enqueued_jobs(only: ProcessPatientChangesetsJob)
    end
    # rubocop:enable Style/BlockDelimiters

    perform_enqueued_jobs(only: CommitPatientChangesetsJob)

    click_on import_class.order(:created_at).last.created_at.to_fs(:long),
             match: :first
  end
end
