#!/usr/bin/env ruby
# frozen_string_literal: true

require "debug"
require "aws-sdk-accessanalyzer"
require "aws-sdk-core"
require "aws-sdk-ec2"
require "aws-sdk-ecr"
require "aws-sdk-iam"
require "aws-sdk-rds"
require "aws-sdk-s3"
require "optparse"

module AwsAccountSetup
  COMMANDS = %i[
    check_default_security_group
    enable_db_delete_protection
    enable_scan_on_push
    check_s3_secure_transport_policy
    check_github_copilot_policy
    create_external_access_console_analyzer
    create_unused_access_console_analyzer
  ].freeze

  class << self
    def enable_db_delete_protection
      rds_client = Aws::RDS::Client.new

      dbs_without_protection =
        rds_client.describe_db_clusters.db_clusters.reject(
          &:deletion_protection
        )

      dbs_without_protection.each do |cluster|
        print "Enabling deletion protection for #{cluster.db_cluster_identifier} ... "
        rds_client.modify_db_cluster(
          db_cluster_identifier: cluster.db_cluster_identifier,
          deletion_protection: true,
          apply_immediately: true
        )
        puts "done"
      end
    end

    def enable_scan_on_push
      ecr_client = Aws::ECR::Client.new

      current_config =
        ecr_client.get_registry_scanning_configuration.to_h[
          :scanning_configuration
        ]

      print "Enabling scan on push at registry level ... "

      scan_on_push_enabled =
        current_config[:rules]&.any? do |rule|
          rule[:scan_frequency] == "SCAN_ON_PUSH"
        end

      if scan_on_push_enabled
        puts "already enabled"
        return
      end

      ecr_client.put_registry_scanning_configuration(
        scan_type: "BASIC",
        rules: [
          {
            scan_frequency: "SCAN_ON_PUSH",
            repository_filters: [{ filter: "*", filter_type: "WILDCARD" }]
          }
        ]
      )
      puts "done"
    end

    def check_s3_secure_transport_policy
      s3_client = Aws::S3::Client.new

      buckets = s3_client.list_buckets.buckets.map(&:name)

      buckets.each do |bucket|
        print "Ensuring bucket #{bucket} has secure transport policy ... "
        policy =
          begin
            JSON.parse(s3_client.get_bucket_policy(bucket: bucket).policy.read)
          rescue Aws::S3::Errors::NoSuchBucketPolicy
            nil
          end

        has_secure_transport =
          policy
            &.dig("Statement")
            &.any? do |statement|
              statement["Effect"] == "Deny" &&
                statement.dig("Condition", "Bool", "aws:SecureTransport") ==
                  "false"
            end

        if has_secure_transport
          puts "policy exists"
        else
          secure_transport_policy = {
            Version: "2012-10-17",
            Statement: [
              {
                Sid: "ForceHTTPS",
                Effect: "Deny",
                Principal: "*",
                Action: "s3:*",
                Resource: [
                  "arn:aws:s3:::#{bucket}",
                  "arn:aws:s3:::#{bucket}/*"
                ],
                Condition: {
                  Bool: {
                    "aws:SecureTransport": "false"
                  }
                }
              }
            ]
          }

          s3_client.put_bucket_policy(
            { bucket: bucket, policy: secure_transport_policy.to_json }
          )
          puts "policy added"
        end
      end
    end

    def create_unused_access_console_analyzer
      create_analyzer(
        "UnusedAccess-ConsoleAnalyzer-eu-west-2",
        "ACCOUNT_UNUSED_ACCESS"
      )
    end

    def create_external_access_console_analyzer
      create_analyzer("ExternalAccess-ConsoleAnalyzer-eu-west-2", "ACCOUNT")
    end

    def check_github_copilot_policy
      print "Checking GitHubActionsRole for wildcard actions ... "

      iam_client = Aws::IAM::Client.new
      resp =
        iam_client.get_role_policy(
          role_name: "GitHubActionsRole",
          policy_name: "custom_copilot_policy"
        )

      policy = JSON.parse(URI.decode_www_form_component(resp.policy_document))

      replacement_made = false
      policy["Statement"].each do |statement|
        unless statement["Effect"] == "Allow" &&
                 Array(statement["Action"]).include?("*")
          next
        end
        statement["Action"] = %w[
          ecr:GetAuthorizationToken
          ecr:PutImage
          ecr:BatchCheckLayerAvailability
          ecr:CompleteLayerUpload
          ecr:UploadLayerPart
          ecr:InitiateLayerUpload
          cloudformation:GetTemplateSummary
          cloudformation:ListStackInstances
          cloudformation:DescribeStacks
          ssm:GetParameter
          ssm:GetParametersByPath
          sts:AssumeRole
          sts:GetCallerIdentity
        ]
        replacement_made = true
      end

      if replacement_made
        iam_client.put_role_policy(
          role_name: resp.role_name,
          policy_name: resp.policy_name,
          policy_document: policy.to_json
        )
        puts "found and fixed"
      else
        puts "none found"
      end
    end

    def check_default_security_group
      print "Checking that all VPCs default security groups have no rules ... "

      mavis_vpc_ids = mavis_vpcs.map(&:vpc_id)
      default_sgs_and_vpcs_with_rules =
        ec2_client
          .describe_security_groups(
            filters: [
              { name: "vpc-id", values: mavis_vpc_ids },
              { name: "group-name", values: ["default"] }
            ]
          )
          .security_groups
          .reject { _1.ip_permissions.empty? }
          .map { |sg| [sg, mavis_vpcs.find { _1.vpc_id == sg.vpc_id }] }

      if default_sgs_and_vpcs_with_rules.empty?
        puts "done"
        return
      end

      puts "found"
      puts "\nThe default security groups have inbound rules:\n\n"

      default_sgs_and_vpcs_with_rules.each do |sg, vpc|
        puts "  #{name_for_vpc(vpc)} #{sg.group_id}"
      end

      print "\nDo you want to delete these inbound rules? (y/N) "
      if gets.chomp.downcase == "y"
        default_sgs_and_vpcs_with_rules.each do |sg, vpc|
          puts "Removing rules from #{name_for_vpc(vpc)} (#{sg.group_id})"

          ec2_client.revoke_security_group_ingress(
            group_id: sg.group_id,
            ip_permissions: sg.ip_permissions
          )
        end
      end
    end

    private

    def ec2_client
      @ec2_client ||= Aws::EC2::Client.new
    end

    def mavis_vpcs
      @mavis_vpcs ||=
        ec2_client.describe_vpcs(
          filters: [{ name: "tag:Name", values: ["copilot-mavis-*"] }]
        ).vpcs
    end

    def name_for_vpc(vpc)
      vpc.tags.find { |t| t.key == "Name" }&.value || vpc.vpc_id
    end

    def create_analyzer(analyzer_name, analyzer_type)
      print "Checking for the existence of the #{analyzer_name} of type #{analyzer_type} ... "

      aa_client = Aws::AccessAnalyzer::Client.new(region: "eu-west-2")

      begin
        existing_analyzer =
          aa_client
            .list_analyzers(type: analyzer_type)
            .analyzers
            .find { _1.name == analyzer_name }

        if existing_analyzer
          puts "found"
        else
          puts "NOT found"
          puts "Creating #{analyzer_name} of type #{analyzer_type}..."

          aa_client.create_analyzer(analyzer_name:, type: analyzer_type)
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  parser =
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$PROGRAM_NAME} [options] COMMAND"

      opts.on("-h", "--help", "Display help") do
        puts opts
        puts ""
        puts "Available commands:"
        puts AwsAccountSetup::COMMANDS.map { "  #{_1}" }
        exit
      end
    end

  parser.parse!

  command = ARGV.shift&.to_sym
  if command == :all
    AwsAccountSetup::COMMANDS.each { AwsAccountSetup.send(_1) }
  elsif AwsAccountSetup::COMMANDS.include? command
    AwsAccountSetup.send(command)
  end
end
