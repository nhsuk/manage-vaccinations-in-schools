require "load_example_campaign"

desc <<DESC
Load campaign example file into db

Arguments:
  example_file: Path to example file (default: db/sample_data/example-hpv-campaign.json)

Options (set these as env vars, e.g. seed=42):
  new_campaign: Don't try to find existing campaign and add to it. (default: false)
  in_progress: Set all sessions to in-progress. (default: false)
DESC

task :load_campaign_example,
     %i[example_file new_campaign] => :environment do |_task, args|
  new_campaign =
    args.fetch(:new_campaign) { ENV.fetch("new_campaign", false) }.in? [
            true,
            "true",
            "1",
            "yes"
          ]
  in_progress =
    args.fetch(:in_progress) { ENV.fetch("in_progress", false) }.in? [
            true,
            "true",
            "1",
            "yes"
          ]

  example_file =
    args.fetch(:example_file, "db/sample_data/example-hpv-campaign.json")

  LoadExampleCampaign.load(example_file:, new_campaign:, in_progress:)
end
