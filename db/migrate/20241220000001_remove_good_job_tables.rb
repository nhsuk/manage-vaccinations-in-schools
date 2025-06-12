# frozen_string_literal: true

class RemoveGoodJobTables < ActiveRecord::Migration[7.2]
  def up
    # Remove Good Job tables if they exist
    drop_table :good_job_batches if table_exists?(:good_job_batches)
    drop_table :good_job_executions if table_exists?(:good_job_executions)
    drop_table :good_jobs if table_exists?(:good_jobs)
    drop_table :good_job_processes if table_exists?(:good_job_processes)
    drop_table :good_job_settings if table_exists?(:good_job_settings)
  end

  def down
    # This migration is irreversible as we're switching to Sidekiq
    raise ActiveRecord::IrreversibleMigration, "Cannot recreate Good Job tables"
  end
end
