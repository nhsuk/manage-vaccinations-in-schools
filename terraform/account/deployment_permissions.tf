################ Deploy Mavis ################
resource "aws_iam_role" "mavis_deploy" {
  name        = "GithubDeployMavisAndInfrastructure"
  description = "Role allowing terraform deployment from github workflows"
  assume_role_policy = templatefile("resources/iam_role_github_trust_policy_${var.environment}.json.tftpl", {
    account_id = var.account_id
  })
}

resource "aws_iam_policy" "mavis_deploy" {
  name        = "DeployMavisResources"
  description = "Permissions for GithubDeployMavisAndInfrastructure role"
  policy      = file("resources/iam_policy_DeployMavisResources.json")
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_role_policy_attachment" "mavis_deploy" {
  for_each   = local.mavis_deploy_policies
  role       = aws_iam_role.mavis_deploy.name
  policy_arn = each.value
}

################ Deploy Data replication ################
resource "aws_iam_role" "data_replication_deploy" {
  name        = "GithubDeployDataReplicationInfrastructure"
  description = "Role to be assumed by github workflows dealing with the creation and destruction of the data-replication infrastructure."
  assume_role_policy = templatefile("resources/iam_role_github_trust_policy_${var.environment}.json.tftpl", {
    account_id = var.account_id
  })
}

resource "aws_iam_policy" "data_replication_deploy" {
  name        = "DeployDataReplicationResources"
  description = "Policy for deploying resources needed to set up the data-replication construction. This is used for testing data modifactions befor acting on the proper database."
  policy      = file("resources/iam_policy_DeployDataReplicationResources.json")
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_role_policy_attachment" "data_replication" {
  for_each   = local.data_replication_policies
  role       = aws_iam_role.data_replication_deploy.name
  policy_arn = each.value
}

resource "aws_iam_role" "data_replication_snapshot" {
  name        = "DatabaseSnapshotRole"
  description = "Role to be assumed by the data replication workflow for taking on-demand DB snapshots"
  assume_role_policy = templatefile("resources/iam_role_github_trust_policy_${var.environment}.json.tftpl", {
    account_id = var.account_id
  })
}

resource "aws_iam_policy" "db_snapshot_policy" {
  name        = "DatabaseSnapshotPolicy"
  description = "Policy to take DB snapshots"
  policy      = file("resources/iam_policy_DatabaseSnapshotPolicy.json")
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_role_policy_attachment" "db_snapshot" {
  role       = aws_iam_role.data_replication_snapshot.name
  policy_arn = aws_iam_policy.db_snapshot_policy.arn
}

################# Deploy Monitoring ################

resource "aws_iam_role" "monitoring_deploy" {
  name        = "GithubDeployMonitoring"
  description = "Role allowing terraform deployment of monitoring resources from github workflows"
  assume_role_policy = templatefile("resources/iam_role_github_trust_policy_${var.environment}.json.tftpl", {
    account_id = var.account_id
  })
}

resource "aws_iam_policy" "monitoring_deploy" {
  name        = "DeployMonitoringResources"
  description = "Permissions for GithubDeployMonitoring role"
  policy      = file("resources/iam_policy_DeployMonitoringResources.json")
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_role_policy_attachment" "monitoring_deploy" {
  for_each   = local.monitoring_policies
  role       = aws_iam_role.monitoring_deploy.name
  policy_arn = each.value
}

################ DMS Policies ################

resource "aws_iam_policy" "dms" {
  name   = "DMSGithubPolicy"
  policy = file("resources/iam_policy_DMSGithubPolicy.json")
}

resource "aws_iam_role_policy_attachment" "mavis_dms" {
  role       = aws_iam_role.mavis_deploy.name
  policy_arn = aws_iam_policy.dms.arn
}
