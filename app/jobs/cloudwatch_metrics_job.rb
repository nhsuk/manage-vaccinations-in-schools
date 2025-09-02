# frozen_string_literal: true

# app/jobs/cloudwatch_db_counts_job.rb
class CloudwatchDbCountsJob
  include Sidekiq::Job

  def perform
    cloudwatch = Aws::CloudWatch::Client.new

    metric_data = [
      {
        metric_name: "DailyActiveUserCount",
        value: User.active_in_past_day.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "WeeklyActiveUserCount",
        value: User.active_in_past_week.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "PatientCount",
        value: Patient.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "VaccinationCount",
        value: VaccinationRecord.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "CompletedSessionCount",
        value: Session.completed.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "ScheduledSessionCount",
        value: Session.scheduled.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "InProgressSessionCount",
        value: Session.in_progress.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "UnscheduledSessionCount",
        value: Session.unscheduled.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "ClassImportCount",
        value: ClassImport.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "CohortImportCount",
        value: CohortImport.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      },
      {
        metric_name: "ImmunisationImportCount",
        value: ImmunisationImport.count,
        unit: "Count",
        dimensions: [{ name: "Environment", value: Rails.env }],
        timestamp: Time.current
      }
    ]

    cloudwatch.put_metric_data(
      namespace: "mavis/db_counts",
      metric_data: metric_data
    )
  end
end
