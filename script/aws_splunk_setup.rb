# frozen_string_literal: true

def usage
  puts "Usage: RAILS_ENV=staging bin/rails runner script/aws_splunk_setup.rb \
<environment> [--cleanup]"
  puts
  puts "Needs RAILS_ENV to be set to staging or production, and an active AWS"
  puts "session with the necessary permissions."
  puts
  puts "Arguments:"
  puts "  environment    - The Copilot environment name (test, training, etc)"
  puts "  --cleanup      - Remove the resources created by this script (experimental)"
  exit 1
end

ENVIRONMENT = ARGV[0]

usage if ENVIRONMENT.blank? || !defined?(Settings)

SPLUNK_INDEX = Settings.splunk.index
HEC_TOKEN = Settings.splunk.hec_token
HEC_ENDPOINT =
  "https://firehose.inputs.splunk.aws.digital.nhs.uk/services/collector/event"

# Get AWS account ID and region
ACCOUNT_ID = `aws sts get-caller-identity --query "Account" --output text`.strip
REGION = "eu-west-2"

# S3 bucket for errors
S3_BUCKET_NAME = "mavis-#{Rails.env}-splunk-firehose-errors".freeze
S3_BUCKET_ARN = "arn:aws:s3:::#{S3_BUCKET_NAME}".freeze

# IAM roles for CloudWatch and Firehose
IAM_CLOUDWATCH_ROLE_NAME = "mavis-#{Rails.env}-splunk-cloudwatch".freeze
IAM_CLOUDWATCH_ROLE_ARN =
  "arn:aws:iam::#{ACCOUNT_ID}:role/#{IAM_CLOUDWATCH_ROLE_NAME}".freeze
IAM_CLOUDWATCH_POLICY_NAME = "#{IAM_CLOUDWATCH_ROLE_NAME}-policy".freeze

IAM_FIREHOSE_ROLE_NAME = "mavis-#{Rails.env}-splunk-firehose".freeze
IAM_FIREHOSE_ROLE_ARN =
  "arn:aws:iam::#{ACCOUNT_ID}:role/#{IAM_FIREHOSE_ROLE_NAME}".freeze
IAM_FIREHOSE_POLICY_NAME = "#{IAM_FIREHOSE_ROLE_NAME}-policy".freeze

# Firehose stream that sends logs to Splunk
FIREHOSE_STREAM_NAME = "mavis-#{Rails.env}-splunk-firehose".freeze
FIREHOSE_STREAM_ARN =
  "arn:aws:firehose:#{REGION}:#{ACCOUNT_ID}:deliverystream/#{FIREHOSE_STREAM_NAME}".freeze

LOG_GROUP_NAME = "/copilot/mavis-#{ENVIRONMENT}-webapp".freeze
LOG_FILTER_NAME = "mavis-#{Rails.env}-splunk-firehose-filter".freeze

def main
  check_aws_login

  if ARGV.include?("--cleanup")
    cleanup
  else
    create_s3_bucket
    create_iam_role_and_policy
    create_firehose_stream
    create_cloudwatch_subscription_filter
  end

  puts "Done! 🎉"
end

def check_aws_login
  return if system("aws sts get-caller-identity &>/dev/null")

  puts "Error: Not signed into AWS CLI. Please run 'aws sso login' first."
  exit 1
end

# TODO: Make this work with multiple subscription filters. Currently it will
# go ahead and delete the IAM role/bucket/firehose even if other subscription
# filters exist that depend on them.
def cleanup
  puts "Removing resources..."

  puts "Deleting CloudWatch subscription filter #{LOG_FILTER_NAME}..."
  system(
    "aws logs delete-subscription-filter \
      --log-group-name #{LOG_GROUP_NAME} \
      --filter-name #{LOG_FILTER_NAME}"
  ) || exit(1)

  puts "Deleting Firehose stream #{FIREHOSE_STREAM_NAME}..."
  system(
    "aws firehose delete-delivery-stream --delivery-stream-name #{FIREHOSE_STREAM_NAME}"
  )

  puts "Deleting S3 bucket #{S3_BUCKET_NAME}..."
  system("aws s3 rb s3://#{S3_BUCKET_NAME} --force")

  puts "Deleting IAM role policies..."
  system(
    "aws iam delete-role-policy --role-name #{IAM_CLOUDWATCH_ROLE_NAME} \
                                --policy-name #{IAM_CLOUDWATCH_POLICY_NAME}"
  )
  system(
    "aws iam delete-role-policy --role-name #{IAM_FIREHOSE_ROLE_NAME} \
                                --policy-name #{IAM_FIREHOSE_POLICY_NAME}"
  )

  puts "Deleting IAM roles..."
  system("aws iam delete-role --role-name #{IAM_CLOUDWATCH_ROLE_NAME}")
  system("aws iam delete-role --role-name #{IAM_FIREHOSE_ROLE_NAME}")
end

def create_s3_bucket
  if system("aws s3api head-bucket --bucket #{S3_BUCKET_NAME} &>/dev/null")
    return puts "S3 bucket #{S3_BUCKET_NAME} already exists"
  end

  puts "Creating bucket #{S3_BUCKET_NAME}..."
  system("aws s3 mb s3://#{S3_BUCKET_NAME}") || exit(1)
end

def create_iam_role_and_policy
  create_cloudwatch_role_and_policy
  create_firehose_role_and_policy

  puts "Waiting 5s for IAM roles and policies to be ready..."
  sleep 5
end

def create_cloudwatch_role_and_policy
  if system(
       "aws iam get-role --role-name #{IAM_CLOUDWATCH_ROLE_NAME} &>/dev/null"
     )
    return puts "IAM role #{IAM_CLOUDWATCH_ROLE_NAME} already exists"
  end

  puts "Creating CloudWatch IAM role #{IAM_CLOUDWATCH_ROLE_NAME}..."
  assume_role_policy = {
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          Service: "logs.#{REGION}.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      }
    ]
  }.to_json

  system(
    "aws iam create-role --role-name #{IAM_CLOUDWATCH_ROLE_NAME} \
                         --assume-role-policy-document '#{assume_role_policy}'"
  ) || exit(1)

  role_policy = {
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: "firehose:PutRecord",
        Resource: FIREHOSE_STREAM_ARN
      }
    ]
  }.to_json

  system(
    "aws iam put-role-policy --role-name #{IAM_CLOUDWATCH_ROLE_NAME} \
                             --policy-name #{IAM_CLOUDWATCH_POLICY_NAME} \
                             --policy-document '#{role_policy}'"
  ) || exit(1)
end

def create_firehose_role_and_policy
  if system(
       "aws iam get-role --role-name #{IAM_FIREHOSE_ROLE_NAME} &>/dev/null"
     )
    return puts "IAM role #{IAM_FIREHOSE_ROLE_NAME} already exists"
  end

  puts "Creating Firehose IAM role #{IAM_FIREHOSE_ROLE_NAME}..."
  assume_role_policy = {
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          Service: "firehose.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      }
    ]
  }.to_json

  system(
    "aws iam create-role --role-name #{IAM_FIREHOSE_ROLE_NAME} \
                         --assume-role-policy-document '#{assume_role_policy}'"
  ) || exit(1)

  role_policy = {
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: %w[s3:PutObject s3:GetObject],
        Resource: "#{S3_BUCKET_ARN}/*"
      }
    ]
  }.to_json

  system(
    "aws iam put-role-policy --role-name #{IAM_FIREHOSE_ROLE_NAME} \
                             --policy-name #{IAM_FIREHOSE_POLICY_NAME} \
                             --policy-document '#{role_policy}'"
  ) || exit(1)
end

def create_firehose_stream
  if system(
       "aws firehose describe-delivery-stream --delivery-stream-name \
            #{FIREHOSE_STREAM_NAME} &>/dev/null"
     )
    return puts "Firehose stream #{FIREHOSE_STREAM_NAME} already exists"
  end

  puts "Creating Firehose delivery stream #{FIREHOSE_STREAM_NAME}..."

  splunk_config = {
    HECEndpoint: HEC_ENDPOINT,
    HECToken: HEC_TOKEN,
    HECEndpointType: "Raw",
    S3BackupMode: "FailedEventsOnly",
    ProcessingConfiguration: {
      Enabled: true,
      Processors: [
        {
          Type: "Decompression",
          Parameters: [
            { ParameterName: "CompressionFormat", ParameterValue: "GZIP" }
          ]
        }
      ]
    },
    S3Configuration: {
      RoleARN: IAM_FIREHOSE_ROLE_ARN,
      BucketARN: S3_BUCKET_ARN
    },
    CloudWatchLoggingOptions: {
      Enabled: true,
      LogGroupName: "/aws/kinesisfirehose/#{FIREHOSE_STREAM_NAME}",
      LogStreamName: "SplunkDelivery"
    }
  }.to_json

  system(
    "aws firehose create-delivery-stream \
      --delivery-stream-name #{FIREHOSE_STREAM_NAME} \
      --delivery-stream-type DirectPut \
      --splunk-destination-configuration '#{splunk_config}'"
  ) || exit(1)

  puts "Waiting 20s for Firehose stream to be ready..."
  sleep 20
end

def create_cloudwatch_subscription_filter
  existing_filter =
    `aws logs describe-subscription-filters \
    --log-group-name #{LOG_GROUP_NAME} \
    --query "subscriptionFilters[*].filterName" \
    --output text`.strip

  if existing_filter.present?
    return puts "Subscription filter #{LOG_FILTER_NAME} already exists"
  end

  puts "Creating CloudWatch subscription filter #{LOG_FILTER_NAME}..."
  system(
    "aws logs put-subscription-filter \
      --log-group-name #{LOG_GROUP_NAME} \
      --filter-name #{LOG_FILTER_NAME} \
      --filter-pattern \"\" \
      --destination-arn #{FIREHOSE_STREAM_ARN} \
      --role-arn #{IAM_CLOUDWATCH_ROLE_ARN}"
  ) || exit(1)
end

main
