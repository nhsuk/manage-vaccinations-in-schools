output "firewall_endpoint_ids" {
  description = "Map of AZs to firewall endpoint IDs"
  value = {
    for state in aws_networkfirewall_firewall.this.firewall_status[0].sync_states :
    state.availability_zone => state.attachment[0].endpoint_id
  }
}
