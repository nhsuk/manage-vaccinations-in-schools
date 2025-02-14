output "firewall_endpoint_id" {
  description = "ID of the firewall VPC endpoint"
  value       = tolist(aws_networkfirewall_firewall.this.firewall_status[0].sync_states)[0].attachment[0].endpoint_id
}
