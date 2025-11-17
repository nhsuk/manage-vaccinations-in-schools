# frozen_string_literal: true

module ReportingAPIHelper
  def valid_jwt_payload
    team = create(:team, :with_one_nurse)
    user = team.users.first

    # Ensure the user has session tokens required by Warden callbacks
    user.update!(
      session_token: SecureRandom.hex(32),
      reporting_api_session_token: SecureRandom.hex(32)
    )

    {
      data: {
        user: user.as_json,
        cis2_info: {
          organisation_code: team.organisation.ods_code,
          workgroups: [team.workgroup],
          role_code: CIS2Info::NURSE_ROLE
        }
      }
    }
  end

  def valid_jwt(payload = valid_jwt_payload)
    JWT.encode(payload, Settings.reporting_api.client_app.secret, "HS512")
  end

  def invalid_jwt_payload
    { user: { id: -1 } }
  end

  def jwt_with_invalid_payload
    JWT.encode(
      invalid_jwt_payload,
      Settings.reporting_api.client_app.secret,
      "HS512"
    )
  end
end
