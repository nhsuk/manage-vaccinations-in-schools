################ Deploy Mavis ################
resource "aws_iam_role" "mavis_deploy" {
  name        = "GithubDeployMavisAndInfrastructure"
  description = "Role allowing terraform deployment from github workflows"
  assume_role_policy = templatefile("resources/iam_role_github_trust_policy_${var.environment}.json.tftpl", {
    account_id      = var.account_id
    repository_list = ["repo:nhsuk/manage-vaccinations-in-schools"]
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
    account_id      = var.account_id
    repository_list = ["repo:nhsuk/manage-vaccinations-in-schools"]
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

################# DB Snapshot Policy ################

resource "aws_iam_role" "data_replication_snapshot" {
  name        = "DatabaseSnapshotRole"
  description = "Role to be assumed by the data replication workflow for taking on-demand DB snapshots"
  assume_role_policy = templatefile("resources/iam_role_github_trust_policy_${var.environment}.json.tftpl", {
    account_id      = var.account_id
    repository_list = ["repo:nhsuk/manage-vaccinations-in-schools"]
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
    account_id      = var.account_id
    repository_list = ["repo:nhsuk/manage-vaccinations-in-schools"]
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

################ Deploy ECS Service ################

resource "aws_iam_role" "deploy_ecs_service" {
  name        = "GithubDeployECSService"
  description = "Role allowing terraform deployment of ECS services from github workflows"
  assume_role_policy = templatefile("resources/iam_role_github_trust_policy_${var.environment}.json.tftpl", {
    account_id = var.account_id,
    repository_list = [
      "repo:nhsuk/manage-vaccinations-in-schools",
      "repo:NHSDigital/manage-vaccinations-in-schools-reporting"
    ]
  })
}

resource "aws_iam_policy" "deploy_ecs_service" {
  name        = "DeployECSServiceResources"
  description = "Permissions for GithubDeployECSService role"
  policy      = file("resources/iam_policy_DeployECSServiceResources.json")
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_role_policy_attachment" "deploy_ecs_service" {
  for_each   = local.ecs_deploy_policies
  role       = aws_iam_role.deploy_ecs_service.name
  policy_arn = each.value
}

################ Run tasks for assurance tests ################

resource "aws_iam_role" "github_assurance" {
  count       = var.environment == "development" ? 1 : 0
  name        = "GitHubAssuranceTestRole"
  description = "Grants permissions for running assurance tests on ECS"
  assume_role_policy = templatefile("resources/iam_role_github_trust_policy_${var.environment}.json.tftpl", {
    account_id = var.account_id,
    repository_list = [
      "repo:NHSDigital/manage-vaccinations-in-schools-testing",
      "repo:nhsuk/manage-vaccinations-in-schools"
    ]
  })
  max_session_duration = 32400 # 9 hours
}

resource "aws_iam_policy" "run_ecs_task" {
  name        = "RunEcsTask"
  description = "Permissions for running a standalone ECS task"
  policy      = file("resources/iam_policy_RunECSTask.json")
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_policy" "run_ecs_task_s3_modifications" {
  count       = var.environment == "development" ? 1 : 0
  name        = "RunECSTaskS3Modifications"
  description = "Permissions to manage objects in mavis-end-to-end-test-reports s3 bucket"
  policy      = file("resources/iam_policy_RunECSTaskS3Modifications.json")
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_iam_role_policy_attachment" "run_ecs_task_s3_modifications" {
  count      = var.environment == "development" ? 1 : 0
  role       = aws_iam_role.github_assurance[0].name
  policy_arn = aws_iam_policy.run_ecs_task_s3_modifications[0].arn
}

resource "aws_iam_role_policy_attachment" "run_ecs_task_custom" {
  count      = var.environment == "development" ? 1 : 0
  role       = aws_iam_role.github_assurance[0].name
  policy_arn = aws_iam_policy.run_ecs_task.arn
}

resource "aws_iam_role_policy_attachment" "run_ecs_task_readonly" {
  count      = var.environment == "development" ? 1 : 0
  role       = aws_iam_role.github_assurance[0].name
  policy_arn = local.base_policies.read
}

resource "aws_iam_role_policy_attachment" "run_ecs_task_tagging" {
  count      = var.environment == "development" ? 1 : 0
  role       = aws_iam_role.github_assurance[0].name
  policy_arn = local.base_policies.tagging
}
