# frozen_string_literal: true

require "rufus/scheduler"
require "net/http"
require "uri"
require "prometheus_parser"
require "aws-sdk-cloudwatch"

#TODO: decide which environments to run this in, metrics cost $0.30/metric/month (billed on hourly basis)...
unless Rails.env.test?
  scheduler = Rufus::Scheduler.new
  uri = URI("http://localhost:9394/metrics")
  Aws::CloudWatch::Client.new

  scheduler.every "30s" do
    response = Net::HTTP.get(uri)
    timestamp = Time.zone.now.utc

    parsed_metrics = PrometheusParser.parse(response)

    metric_data = []
    parsed_metrics.each do |sample|
      metric_data << {
        metric_name: sample[:key], # e.g., 'puma_workers' or 'puma_cpu_usage_percent'
        dimensions:
          sample[:attrs].map { |k, v| { name: k.to_s, value: v.to_s } },
        value: sample[:value],
        unit: "None", # Customize per metric if needed (e.g., 'Percent' for CPU)
        # We also need to add some identifiers for environment, service, task/container id
        timestamp:
      }
    end
    Rails.logger.info "Sending #{metric_data} metrics to CloudWatch" #TODO: Remove this testing log statement

    # Send in batches of 1000 (AWS limit)
    # metric_data.each_slice(1000) do |batch|
    #   cw_client.put_metric_data(
    #     namespace: 'MyRailsApp',  # Customize (e.g., 'Production/MyApp')
    #     metric_data: batch
    #   )
    # end
  end
end
