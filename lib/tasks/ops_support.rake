# frozen_string_literal: true

namespace :ops_support do
  desc "Create an organisation and team for ops support users to access ops tools."
  task seed: :environment do
    organisation =
      Organisation.find_or_create_by!(ods_code: CIS2Info::SUPPORT_ORGANISATION)

    Team.find_or_create_by!(
      organisation:,
      name: "Operational Support Team",
      workgroup: CIS2Info::SUPPORT_WORKGROUP,
      careplus_venue_code: "XXX",
      email: "england.mavis@nhs.net",
      phone: "01234 567890",
      privacy_notice_url: "https://www.example.com/privacy",
      privacy_policy_url: "https://www.example.com/privacy",
      days_before_consent_reminders: 0,
      days_before_consent_requests: 0
    )
  end
end
