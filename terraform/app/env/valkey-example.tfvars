# Example Terraform variables for Valkey Self-Designed Cluster/Sidekiq setup
# Copy this file and customize for your environment

# Basic configuration
environment = "qa" # or "production", "preview", "sandbox-alpha", etc.

########## VALKEY SELF-DESIGNED CLUSTER CONFIGURATION ##########

# Engine and port configuration
valkey_engine_version = "7.2" # Valkey engine version
valkey_port           = 6379  # Default Redis port

# Node configuration
valkey_node_type       = "cache.t3.micro" # Node type (cache.t3.micro for sandbox, cache.r6g.large+ for production)
valkey_num_cache_nodes = 1                # Number of cache nodes (1 for single node, 2+ for replication)

# Backup configuration
valkey_snapshot_retention_limit = 7                     # Snapshot retention days (0 to disable)
valkey_snapshot_window          = "03:00-05:00"         # Daily snapshot window (UTC)
valkey_maintenance_window       = "sun:05:00-sun:06:00" # Weekly maintenance window (UTC)

# Encryption
valkey_kms_key_id = null # Optional KMS key for encryption

# Logging
valkey_log_retention_days = 14

# Sidekiq service
sidekiq_replicas = 2 # Adjust based on job volume

########## ENVIRONMENT-SPECIFIC RECOMMENDATIONS ##########

# Sandbox environments (minimal cost):
# valkey_node_type = "cache.t3.micro"
# valkey_num_cache_nodes = 1
# valkey_snapshot_retention_limit = 0
# valkey_log_retention_days = 3
# sidekiq_replicas = 1

# Production environments:
# valkey_node_type = "cache.r6g.large"
# valkey_num_cache_nodes = 2
# valkey_snapshot_retention_limit = 14
# valkey_log_retention_days = 30
# sidekiq_replicas = 3
