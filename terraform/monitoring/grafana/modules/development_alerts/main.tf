terraform {
  required_version = "~> 1.13.3"
  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.8.0"
    }
  }
}




