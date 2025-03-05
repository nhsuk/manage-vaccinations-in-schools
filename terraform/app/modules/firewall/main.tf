############## Firewall ################
resource "aws_networkfirewall_rule_group" "this" {
  capacity = 100
  name     = "stateful-domain-rules"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_string = <<EOF
alert tcp any any -> any 443 (msg:"Log all TCP traffic to 443"; sid:1000000; rev:1;)
pass tcp any any -> any 443 (msg:"Allow all TCP traffic to 443"; sid:1000001; rev:1;)
drop ip any any -> any any (msg:"Drop all other traffic"; sid:9999999; rev:1;)
EOF
    }
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "this" {
  name = "${var.environment}-firewall-policy"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateful_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.this.arn
    }
    stateful_default_actions = ["aws:drop_strict"]
  }
}

resource "aws_networkfirewall_firewall" "this" {
  name                = "firewall-${var.environment}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn  # Assumes policy is defined elsewhere
  vpc_id              = var.vpc_id

  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall
    content {
      subnet_id = subnet_mapping.value.id
    }
  }
}

############## LOGGING ################
resource "aws_cloudwatch_log_group" "this" {
  name              = "mavis-${var.environment}-firewall"
  retention_in_days = var.log_retention_days
  skip_destroy      = var.retain_logs
}

resource "aws_networkfirewall_logging_configuration" "this" {
  firewall_arn = aws_networkfirewall_firewall.this.arn
  logging_configuration {
    log_destination_config {
      log_destination = { logGroup = aws_cloudwatch_log_group.this.name }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
    log_destination_config {
      log_destination = { logGroup = aws_cloudwatch_log_group.this.name }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}
