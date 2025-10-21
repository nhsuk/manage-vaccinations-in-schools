resource "aws_accessanalyzer_analyzer" "unused" {
  analyzer_name = "UnusedAccess-ConsoleAnalyzer-eu-west-2"
  type          = "ACCOUNT_UNUSED_ACCESS"
  configuration {
    unused_access {
      unused_access_age = 90
    }
  }
}

resource "aws_accessanalyzer_analyzer" "external" {
  analyzer_name = "ExternalAccess-ConsoleAnalyzer-eu-west-2"
  type          = "ACCOUNT"
}
