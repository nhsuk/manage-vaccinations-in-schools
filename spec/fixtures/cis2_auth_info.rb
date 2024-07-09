#!/usr/bin/env ruby
# frozen_string_literal: true

CIS2_AUTH_INFO = {
  "provider" => :cis2,
  "uid" => "123456789012",
  "info" => {
    "name" => "Nurse Test",
    "email" => "nurse.test@example.nhs.uk",
    "email_verified" => nil,
    "nickname" => nil,
    "first_name" => "Nurse",
    "last_name" => "Test",
    "gender" => nil,
    "image" => nil,
    "phone" => nil,
    "urls" => {
      "website" => nil
    }
  },
  "extra" => {
    "raw_info" => {
      "nhsid_useruid" => "123456789012",
      "name" => "Flo Nurse",
      "nhsid_nrbac_roles" => [
        {
          "person_orgid" => "1111222233334444",
          "person_roleid" => "5555666677778888",
          "org_code" => "AB12",
          "role_name" =>
            "\"Admin and Clerical\":\"Admin and Clerical\":\"Privacy Officer\"",
          "role_code" => "S8002:G8003:R0001",
          "activities" => [
            "Receive Self Claimed LR Alerts",
            "Receive Legal Override and Emergency View Alerts",
            "Receive Sealing Alerts"
          ],
          "activity_codes" => %w[B0016 B0015 B0018]
        },
        {
          "person_orgid" => "1234123412341234",
          "person_roleid" => "5678567856785678",
          "org_code" => "CD34",
          "role_name" =>
            "\"Clinical\":\"Clinical Provision\":\"Nurse Access Role\"",
          "role_code" => "S8000:G8000:R8001",
          "activities" => [
            "Personal Medication Administration",
            "Perform Detailed Health Record",
            "Amend Patient Demographics",
            "Perform Patient Administration",
            "Verify Health Records"
          ],
          "activity_codes" => %w[B0428 B0380 B0825 B0560 B8028]
        }
      ],
      "given_name" => "Nurse",
      "family_name" => "Flo",
      "nhsid_user_orgs" => [
        { "org_name" => "LAVENDER TOWN HEALTH", "org_code" => "AB12" },
        { "org_name" => "KANTO HEALTH ORG", "org_code" => "CD34" }
      ],
      "uid" => "555057896106",
      "email" => "nurse.flo@example.nhs.uk",
      "sub" => "123456789012",
      "subname" => "123456789012",
      "iss" => "http://localhost:4000/not/used",
      "selected_roleid" => "5555666677778888"
    }
  }
}.freeze
