# frozen_string_literal: true

require "aws-sdk-cloudwatch"

namespace :cloudwatch do
  desc "Publish test metric data to CloudWatch namespace test/export"
  task publish_test_metric: :environment do
    cloudwatch = Aws::CloudWatch::Client.new

    metric_data = [
      {
        metric_name: "TestMetric",
        value: 1.0,
        unit: "Count",
        dimensions: [{ name: "Environment", value: "Test" }],
        timestamp: Time.current
      }
    ]

    response =
      cloudwatch.put_metric_data(
        namespace: "test/export",
        metric_data: metric_data
      )

    puts "✅ Successfully published TestMetric to CloudWatch namespace 'test/export'"
    puts "📊 Metric Details:"
    puts "   - Name: TestMetric"
    puts "   - Value: 1.0"
    puts "   - Unit: Count"
    puts "   - Dimension: Environment=Test"
    puts "   - Timestamp: #{Time.current}"
    puts "📋 Response HTTP Status: #{response.successful? ? "Success" : "Failed"}"
  rescue Aws::CloudWatch::Errors::ServiceError => e
    puts "❌ AWS CloudWatch Service Error: #{e.message}"
    puts "🔧 Please check your AWS credentials and permissions for CloudWatch"
    exit 1
  rescue Aws::Errors::MissingCredentialsError => e
    puts "❌ AWS Credentials Missing: #{e.message}"
    puts "🔧 Please configure AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION)"
    exit 1
  rescue StandardError => e
    puts "❌ Unexpected Error: #{e.message}"
    puts "🔧 #{e.backtrace.first}"
    exit 1
  end
end
