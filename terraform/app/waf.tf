resource "aws_wafv2_web_acl" "mavis_waf" {
  name        = "mavis-waf-${var.environment}"
  description = "WAF ACL for Mavis application"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.waf_logging_enabled
    metric_name                = "mavis-waf-${var.environment}"
    sampled_requests_enabled   = var.waf_logging_enabled
  }

  lifecycle {
    ignore_changes = [rule]
  }
}

resource "aws_wafv2_web_acl_association" "alb_association" {
  resource_arn = aws_lb.app_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.mavis_waf.arn

  depends_on = [aws_wafv2_web_acl_rule_group_association.rate_limit]
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  count             = var.waf_logging_enabled ? 1 : 0
  name              = "aws-waf-logs-mavis-${var.environment}"
  retention_in_days = 30
}

resource "aws_wafv2_web_acl_logging_configuration" "mavis_waf_logging" {
  count                   = var.waf_logging_enabled ? 1 : 0
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs[0].arn]
  resource_arn            = aws_wafv2_web_acl.mavis_waf.arn

  depends_on = [aws_cloudwatch_log_group.waf_logs]
}

######### WAF RULE GROUP ASSOCIATIONS #########

resource "aws_wafv2_web_acl_rule_group_association" "ip_reputation_list" {
  rule_name   = "AWSManagedRulesAmazonIpReputationList"
  priority    = 10
  web_acl_arn = aws_wafv2_web_acl.mavis_waf.arn

  managed_rule_group {
    name        = "AWSManagedRulesAmazonIpReputationList"
    vendor_name = "AWS"
  }

  override_action = var.waf_rule_actions["ip_reputation_list"] == "COUNT" ? "count" : "none"

  depends_on = [aws_wafv2_web_acl.mavis_waf]
}

resource "aws_wafv2_web_acl_rule_group_association" "common_rule_set" {
  rule_name   = "AWSManagedRulesCommonRuleSet"
  priority    = 20
  web_acl_arn = aws_wafv2_web_acl.mavis_waf.arn

  managed_rule_group {
    name        = "AWSManagedRulesCommonRuleSet"
    vendor_name = "AWS"
  }

  override_action = var.waf_rule_actions["core_rule_set"] == "COUNT" ? "count" : "none"

  depends_on = [aws_wafv2_web_acl_rule_group_association.ip_reputation_list]
}

resource "aws_wafv2_web_acl_rule_group_association" "known_bad_inputs" {
  rule_name   = "AWSManagedRulesKnownBadInputsRuleSet"
  priority    = 30
  web_acl_arn = aws_wafv2_web_acl.mavis_waf.arn

  managed_rule_group {
    name        = "AWSManagedRulesKnownBadInputsRuleSet"
    vendor_name = "AWS"
  }

  override_action = var.waf_rule_actions["known_bad_inputs"] == "COUNT" ? "count" : "none"

  depends_on = [aws_wafv2_web_acl_rule_group_association.common_rule_set]
}

resource "aws_wafv2_web_acl_rule_group_association" "rate_limit" {
  rule_name   = "RateLimitRule"
  priority    = 40
  web_acl_arn = aws_wafv2_web_acl.mavis_waf.arn

  rule_group_reference {
    arn = aws_wafv2_rule_group.rate_limit_group.arn
  }
  depends_on = [aws_wafv2_web_acl_rule_group_association.known_bad_inputs]
}


######### CUSTOM RULE GROUPS #########

resource "aws_wafv2_rule_group" "rate_limit_group" {
  name     = "mavis-rate-limit-${var.environment}"
  scope    = "REGIONAL"
  capacity = 2

  rule {
    name     = "RateLimitRule"
    priority = 0

    action {
      dynamic "count" {
        for_each = var.waf_rule_actions["rate_limiting"] == "COUNT" ? [1] : []
        content {}
      }
      dynamic "block" {
        for_each = var.waf_rule_actions["rate_limiting"] == "BLOCK" ? [1] : []
        content {}
      }
    }

    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limit_threshold
        aggregate_key_type    = "IP"
        evaluation_window_sec = 60
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "mavis-rate-limit-${var.environment}"
    sampled_requests_enabled   = true
  }
}