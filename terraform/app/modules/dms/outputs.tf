output "replication_instance_ip_address" {
  value = aws_dms_replication_instance.dms_instance.replication_instance_private_ips[0]
  description = "Private IP address of the DMS replication instance"
}

output "dms_security_group_id" {
  value = aws_security_group.dms.id
  description = "ID of the DMS security group"
}
