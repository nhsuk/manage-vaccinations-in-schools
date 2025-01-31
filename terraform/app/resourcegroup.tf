resource "aws_resourcegroups_group" "production" {
  name = "mavis-resources-${var.environment_string}"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key    = "Environment"
          Values = [var.environment_string]
        }
      ]
    })
  }
}
