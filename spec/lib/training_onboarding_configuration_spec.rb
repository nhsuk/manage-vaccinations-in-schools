# frozen_string_literal: true

describe TrainingOnboardingConfiguration do
  subject(:call) { described_class.call(ods_code:, workgroup:) }

  let(:ods_code) { "ABC" }
  let(:workgroup) { "abc" }

  let!(:unattached_school) { create(:school, :open) }

  before { create(:school, :open, team: create(:team)) }

  it "generates suitable configuration" do
    expect(call).to eq(
      {
        organisation: {
          ods_code: "ABC"
        },
        team: {
          careplus_venue_code: "ABC",
          email: "abc@example.com",
          name: "ABC (abc) training",
          phone: "07700 900815",
          privacy_notice_url: "https://example.com/privacy-notice-abc",
          privacy_policy_url: "https://example.com/privacy-policy-abc",
          workgroup: "abc"
        },
        programmes: %w[flu hpv menacwy td_ipv],
        subteams: {
          generic: {
            email: "abc@example.com",
            name: "ABC (abc) training",
            phone: "07700 900815"
          }
        },
        users: [
          {
            email: "nurse.abc@example.com",
            family_name: "ABC (abc)",
            given_name: "Nurse",
            password: "nurse.abc@example.com"
          },
          {
            email: "medical-secretary.abc@example.com",
            family_name: "ABC (abc)",
            given_name: "Medical secretary",
            password: "medical-secretary.abc@example.com"
          },
          {
            email: "superuser.abc@example.com",
            family_name: "ABC (abc)",
            given_name: "Superuser",
            password: "superuser.abc@example.com"
          },
          {
            email: "healthcare-assistant.abc@example.com",
            family_name: "ABC (abc)",
            given_name: "Healthcare assistant",
            password: "healthcare-assistant.abc@example.com"
          },
          {
            email: "prescriber.abc@example.com",
            family_name: "ABC (abc)",
            given_name: "Prescriber",
            password: "prescriber.abc@example.com"
          },
          {
            email: "support.abc@example.com",
            family_name: "ABC (abc)",
            given_name: "Support",
            password: "support.abc@example.com"
          }
        ],
        schools: {
          generic: [unattached_school.urn]
        },
        clinics: {
          generic: [
            {
              address_line_1: "Training clinic way",
              address_postcode: "SW1A 1AA",
              address_town: "Training town",
              name: "Training ABC (abc) clinic"
            }
          ]
        }
      }
    )
  end
end
