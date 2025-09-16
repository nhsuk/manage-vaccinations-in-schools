# frozen_string_literal: true

class DropGoodJob < ActiveRecord::Migration[8.0]
  def up
    drop_table :good_jobs
    drop_table :good_job_batches
    drop_table :good_job_executions
    drop_table :good_job_processes
    drop_table :good_job_settings
  end
end
