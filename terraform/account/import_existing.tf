import {
  to = aws_iam_role.mavis_deploy
  id = "GithubDeployMavisAndInfrastructure"
}

import {
  to = aws_iam_policy.mavis_deploy
  id = "arn:aws:iam::${var.account_id}:policy/DeployMavisResources"
}

import {
  for_each = local.mavis_deploy_policies
  to       = aws_iam_role_policy_attachment.mavis_deploy[each.key]
  id       = "GithubDeployMavisAndInfrastructure/${each.value}"
}

import {
  to = aws_iam_role.data_replication_deploy
  id = "GithubDeployDataReplicationInfrastructure"
}

import {
  to = aws_iam_policy.data_replication_deploy
  id = "arn:aws:iam::${var.account_id}:policy/DeployDataReplicationResources"
}

import {
  for_each = local.data_replication_policies
  to       = aws_iam_role_policy_attachment.data_replication[each.key]
  id       = "GithubDeployDataReplicationInfrastructure/${each.value}"
}
