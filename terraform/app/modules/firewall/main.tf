############## NETWORK ################
resource "aws_subnet" "this" {
  vpc_id     = var.vpc_id
  cidr_block = var.firewall_subnet_cidr
  tags = {
    Name = "firewall-subnet-${var.environment}"
  }
}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id
  tags = {
    Name = "firewall-rt-${var.environment}"
  }
}
resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}

resource "aws_route" "private_to_firewall" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = tolist(aws_networkfirewall_firewall.this.firewall_status[0].sync_states)[0].attachment[0].endpoint_id
  depends_on             = [aws_networkfirewall_firewall.this]
}

resource "aws_route" "firewall_to_nat" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

############## Firewall ################
resource "aws_networkfirewall_rule_group" "this" {
  capacity = 100
  name     = "stateful-domain-rules"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<EOF
pass ip any any -> 51.24.47.0/24 any (msg:"Allow traffic after DNS query"; sid:1000000; rev:1; )
pass ip any any -> 18.169.250.0/24 any (msg:"Allow traffic after DNS query"; sid:1000001; rev:1; )
pass ip any any -> 3.8.57.0/24 any (msg:"Allow traffic after DNS query"; sid:1000002; rev:1; )
pass ip 51.24.47.0/24 any -> any any (msg:"Allow traffic after DNS query"; sid:1000003; rev:1; )
pass ip 18.169.250.0/24 any -> any any (msg:"Allow traffic after DNS query"; sid:1000004; rev:1; )
pass ip 3.8.57.0/24 any -> any any (msg:"Allow traffic after DNS query"; sid:1000005; rev:1; )
drop ip any any -> any any (msg:"Drop all other traffic"; sid:9999999; rev:1;)
EOF
      #       rules_string = <<EOF
      # alert dns any any -> any any (msg:"DNS query for .digital.nhs.uk domains"; dns.query; dotprefix; content:".digital.nhs.uk"; endswith; nocase; flowbits:set,allow_domain; sid:1000001; rev:1;)
      # alert dns any any -> any any (msg:"DNS query for .ingest.sentry.io domains"; content:".ingest.sentry.io"; endswith; nocase; flowbits:set,allow_domain; sid:1000002; rev:1;)
      # pass ip any any -> any any (msg:"Allow traffic after DNS query"; flowbits:isset,allow_domain; flow:established; sid:1000000; rev:1; )
      # drop ip any any -> any any (msg:"Drop all other traffic"; sid:9999999; rev:1;)
      # EOF
      #       rules_string = <<EOF
      # pass tls any any -> any any (msg:"Allow outbound TLS to .digital.nhs.uk domains"; ssl_state:client_hello; flow:to_server; tls.sni; content:".digital.nhs.uk"; endswith; nocase; flowbits:set,allowed_flow; sid:1000001; rev:1;)
      # pass tls any any -> any any (msg:"Allow outbound TLS to .ingest.sentry.io domains"; ssl_state:client_hello; flow:to_server; tls.sni; content:".ingest.sentry.io"; endswith; nocase; flowbits:set,allowed_flow; sid:1000002; rev:1;)
      # pass ip any any -> any any (msg:"Allow return traffic for allowed flows"; flowbits:isset,allowed_flow; flow:established; sid:1000000; rev:1; )
      # drop ip any any -> any any (msg:"Drop all other traffic"; sid:9999999; rev:1;)
      # EOF
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
    stateful_default_actions = ["aws:alert_strict"]
  }
}

resource "aws_networkfirewall_firewall" "this" {
  name                = "firewall-${var.environment}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn
  vpc_id              = var.vpc_id
  subnet_mapping {
    subnet_id = aws_subnet.this.id
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
      log_destination = {
        logGroup = aws_cloudwatch_log_group.this.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

####### TODO: Evaluate whether this SG is needed
resource "aws_security_group_rule" "ecs_firewall_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [aws_subnet.this.cidr_block]
  security_group_id = var.ecs_security_group_id
}
