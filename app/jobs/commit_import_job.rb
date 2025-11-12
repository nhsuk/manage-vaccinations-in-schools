# frozen_string_literal: true

class CommitImportJob
  include Sidekiq::Job
  include Sidekiq::Throttled::Job
  include PatientImportConcern

  sidekiq_throttle concurrency: {
                     limit: 1,
                     key_suffix: ->(_) do
                       if Flipper.enabled?(:import_concurrency_per_server)
                         Socket.gethostname
                       else
                         ""
                       end
                     end
                   }

  queue_as :imports

  def perform(import_global_id)
    import = GlobalID::Locator.locate(import_global_id)

    if Flipper.enabled?(:import_search_pds) &&
         Flipper.enabled?(:import_low_pds_match_rate)
      import.validate_pds_match_rate!
      return if import.low_pds_match_rate?
    end

    counts = import.class.const_get(:COUNT_COLUMNS).index_with(0)
    imported_school_move_ids = []

    ActiveRecord::Base.transaction do
      import
        .changesets
        .from_file
        .includes(:school)
        .find_in_batches(batch_size: 100) do |changesets|
          increment_column_counts!(import, counts, changesets)

          import_patients_and_parents(changesets, import)

          imported_school_move_ids |= import_school_moves(changesets, import)

          import_pds_search_results(changesets, import)
        end
      import.postprocess_rows!

      reset_counts(import)

      import.update_columns(
        processed_at: Time.zone.now,
        status: :processed,
        **counts
      )
    end
    SyncPatientTeamJob.perform_later(SchoolMove, imported_school_move_ids)
    import.post_commit!
  end
end
