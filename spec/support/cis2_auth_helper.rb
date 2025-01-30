# frozen_string_literal: true

module CIS2AuthHelper
  def cis2_auth_info
    {
      "provider" => :cis2,
      "uid" => "123456789012",
      "info" => {
        "name" => "Nurse Test",
        "email" => "nurse.test@example.nhs.uk",
        "email_verified" => nil,
        "nickname" => nil,
        "given_name" => "Nurse",
        "family_name" => "Test",
        "gender" => nil,
        "image" => nil,
        "phone" => nil,
        "urls" => {
          "website" => nil
        }
      },
      "extra" => {
        "raw_info" => {
          "id_assurance_level" => "3",
          "authentication_assurance_level" => "3",
          "auth_time" => Time.zone.now.to_i,
          "nhsid_useruid" => "123456789012",
          "name" => "Nurse Test",
          "nhsid_nrbac_roles" => [
            {
              "person_orgid" => "1111222233334444",
              "person_roleid" => "5555666677778888",
              "org_code" => "A9A5A",
              "role_name" =>
                '"Clinical":"Clinical Provision":"Nurse Access Role"',
              "role_code" => "S8000:G8000:R8001",
              "activities" => [],
              "activity_codes" => [],
              "workgroups" => ["schoolagedimmunisations"],
              "workgroups_codes" => ["15025792819"]
            },
            {
              "person_orgid" => "1111222233334444",
              "person_roleid" => "wrong-role",
              "org_code" => "A9A5A",
              "role_name" =>
                '"Clinical":"Clinical Provision":"Health Professional Access Role"',
              "role_code" => "S8000:G8000:R8003",
              "activities" => [],
              "activity_codes" => [],
              "workgroups" => ["schoolagedimmunisations"],
              "workgroups_codes" => ["15025792819"]
            },
            {
              "person_orgid" => "1111222233334444",
              "person_roleid" => "wrong-workgroup",
              "org_code" => "A9A5A",
              "role_name" =>
                '"Clinical":"Clinical Provision":"Nurse Access Role"',
              "role_code" => "S8000:G8000:R8001",
              "activities" => [],
              "activity_codes" => [],
              "workgroups" => [],
              "workgroups_codes" => []
            },
            {
              "person_orgid" => "1234123412341234",
              "person_roleid" => "wrong-organisation",
              "org_code" => "AB12",
              "role_name" =>
                '"Clinical":"Clinical Provision":"Nurse Access Role"',
              "role_code" => "S8000:G8000:R8001",
              "activities" => [],
              "activity_codes" => [],
              "workgroups" => ["schoolagedimmunisations"],
              "workgroups_codes" => ["15025792819"]
            }
          ],
          "given_name" => "Nurse",
          "family_name" => "Test",
          "nhsid_user_orgs" => [
            { "org_name" => "TEST MILITARY MOSPITAL", "org_code" => "A9A5A" },
            { "org_name" => "LAVENDER TOWN HEALTH", "org_code" => "AB12" }
          ],
          "uid" => "555057896106",
          "email" => "nurse.test@example.nhs.uk",
          "sub" => "123456789012",
          "subname" => "123456789012",
          "iss" => "http://localhost:4000/not/used",
          "selected_roleid" => "5555666677778888"
        }
      }
    }
  end

  def cis2_sign_in(user, role: :nurse, org_code: nil, superuser: false)
    workgroups =
      %w[schoolagedimmunisations] + (superuser ? %w[mavissuperusers] : [])

    mock_cis2_auth(
      uid: user.uid,
      given_name: user.given_name,
      family_name: user.family_name,
      email: user.email,
      role:,
      org_code:,
      sid: user.session_token,
      workgroups:
    )

    if page.driver.respond_to? :get
      page.driver.get "/users/auth/cis2/callback"
    else
      visit "/users/auth/cis2/callback"
    end
  end

  # Define a sign_in that is compatible with Devise's sign_in.
  def sign_in(user, role: :nurse, org_code: nil, superuser: false)
    org_code ||= user.organisations.first.ods_code
    cis2_sign_in(user, role:, org_code:, superuser:)
  end

  def mock_cis2_auth(
    uid: "123",
    given_name: "Nurse",
    family_name: "Test",
    email: nil,
    role: :nurse,
    role_code: nil,
    org_code: nil,
    org_name: "Test SAIS Org",
    user_only_has_one_role: false,
    workgroups: nil,
    no_workgroup: false,
    sid: nil,
    selected_roleid: "5555666677778888"
  )
    mock_auth = cis2_auth_info
    raw_info = mock_auth["extra"]["raw_info"]

    if org_code.present?
      raw_info["nhsid_nrbac_roles"][0].merge!(org_code:)
      raw_info["nhsid_user_orgs"][0].merge!(org_code:, org_name:)
    end

    if user_only_has_one_role
      raw_info["nhsid_nrbac_roles"].select! do
        _1["person_roleid"] == selected_roleid
      end
    end

    role_code ||= {
      nurse: "S8000:G8000:R8001",
      admin_staff: "S8000:G8001:R8006"
    }.fetch(role)

    nhsid_nrbac_role = raw_info["nhsid_nrbac_roles"][0]
    nhsid_nrbac_role["role_code"] = role_code
    if no_workgroup
      nhsid_nrbac_role.delete("workgroups")
      nhsid_nrbac_role.delete("workgroups_codes")
    elsif workgroups
      nhsid_nrbac_role["workgroups"] = workgroups
    end

    mock_auth["uid"] = uid
    raw_info["uid"] = uid
    raw_info["sub"] = uid
    raw_info["sid"] = sid
    mock_auth["info"]["given_name"] = given_name
    mock_auth["info"]["family_name"] = family_name
    mock_auth["info"]["email"] = email
    raw_info["given_name"] = given_name
    raw_info["family_name"] = family_name
    raw_info["name"] = "#{given_name} #{family_name}"
    raw_info["email"] = email
    raw_info["selected_roleid"] = selected_roleid

    OmniAuth.config.add_mock(:cis2, mock_auth)
  end
end
