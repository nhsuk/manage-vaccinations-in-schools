# frozen_string_literal: true

GOVUK_NOTIFY_EMAIL_TEMPLATES = {
  consent_clinic_request: "14e88a09-4281-4257-9574-6afeaeb42715",
  consent_confirmation_clinic: "f2921e23-4b73-4e44-abbb-38b0e235db8e",
  consent_confirmation_given: "c6c8dbfc-b429-4468-bd0b-176e771b5a8e",
  consent_confirmation_refused: "5a676dac-3385-49e4-98c2-fc6b45b5a851",
  consent_confirmation_triage: "604ee667-c996-471e-b986-79ab98d0767c",
  consent_school_initial_reminder_doubles:
    "3523d4b8-530b-42dd-8b9b-7fed8d1dfff1",
  consent_school_initial_reminder_flu: "7f85a5b4-5240-4ae9-94f7-43913852943c",
  consent_school_initial_reminder_hpv: "0d78bff0-9dde-4192-8cf8-10e83486b54f",
  consent_school_initial_reminder_mmr: "5462c441-81c0-4ac0-821f-713b4178f8ba",
  consent_school_request_doubles: "9b1a015d-6caa-47c5-a223-f72377586602",
  consent_school_request_flu: "017853bc-2b35-4aff-99b1-193e514613a0",
  consent_school_request_hpv: "7b9bb010-0742-460a-ae25-1922355b6776",
  consent_school_request_mmr: "7e86e688-ceca-4dcc-a1cf-19cb559d38a8",
  consent_school_subsequent_reminder_doubles:
    "ea03aada-0912-4373-91e1-80082071a7aa",
  consent_school_subsequent_reminder_flu:
    "c942ce27-590e-4387-9aa8-5b9b4f2796d1",
  consent_school_subsequent_reminder_hpv:
    "5f70d21d-00b6-41e6-bdc9-e64455972b43",
  consent_school_subsequent_reminder_mmr:
    "5462c441-81c0-4ac0-821f-713b4178f8ba",
  consent_unknown_contact_details_warning:
    "6d746839-a20e-4d50-8a1d-6f3900ff69b2",
  session_clinic_initial_invitation: "88d21cfc-39f6-44a2-98c3-9588e7214ae4",
  session_clinic_subsequent_invitation: "a86a3b3f-a848-41d8-9a6f-d38174981388",
  session_clinic_initial_invitation_ryg: "fc99ac81-9eeb-4df8-9aa0-04f0eb48e37f",
  session_clinic_subsequent_invitation_ryg:
    "eee59c1b-3af4-4ccd-8653-940887066390",
  session_clinic_initial_invitation_rt5: nil,
  session_clinic_subsequent_invitation_rt5: nil,
  session_school_reminder: "8b8a9566-bb03-4b3c-8abc-5bd5a4b8797d",
  triage_vaccination_at_clinic: "3c7461bd-e3cf-4ff9-9053-b4e87490aa45",
  triage_vaccination_at_clinic_ryg: "9faef718-bd76-4c30-93ea-fbe8584388a6",
  triage_vaccination_at_clinic_rt5: nil,
  triage_vaccination_will_happen: "279c517c-4c52-4a69-96cb-31355bfa4e21",
  triage_vaccination_wont_happen: "d1faf47e-ccc3-4481-975b-1ec34211a21f",
  vaccination_administered_flu: "7238ee27-5840-40e5-b9b9-3130ba4cd4fa",
  vaccination_administered_hpv: "8a65d7b5-045c-4f26-8f76-6e593c14cb6d",
  vaccination_administered_menacwy: "38727494-9a81-42b3-9c1f-5c31e55333e7",
  vaccination_administered_mmr: "0b1095db-fb38-4105-9f01-a364fa8bbb1c",
  vaccination_administered_td_ipv: "3abe7ca8-a889-484b-ab9f-07523302eb6a",
  vaccination_already_had: "e37fe0a2-7584-4c25-983a-8f5a11c818a1",
  vaccination_deleted: "1caf1459-abc9-4944-b8c0-deba906ea005",
  vaccination_not_administered: "130fe52a-014a-45dd-9f53-8e65c1b8bb79"
}.freeze

GOVUK_NOTIFY_SMS_TEMPLATES = {
  consent_clinic_request: "03a0d572-ca5b-417e-87c3-838872a9eabc",
  consent_confirmation_given: "3179b434-4f44-4d47-a8ba-651b58c235fd",
  consent_confirmation_refused: "eb34f3ab-0c58-4e56-b6b1-2c179270dfc3",
  consent_school_reminder: "ee3d36b1-4682-4eb0-a74a-7e0f6c9d0598",
  consent_school_request: "c7bd8150-d09e-4607-817d-db75c9a6a966",
  consent_unknown_contact_details_warning:
    "1fd4620d-1c96-4af1-b047-ed13a90b0f44",
  session_clinic_initial_invitation: "790c9c72-729a-40d6-b44d-d480e38f0990",
  session_clinic_subsequent_invitation: "ce7a6a1b-465e-4be4-b9e0-47ddb64f3adb",
  session_clinic_initial_invitation_ryg: "8ef5712f-bb7f-4911-8f3b-19df6f8a7179",
  session_clinic_subsequent_invitation_ryg:
    "018f146d-e7b7-4b63-ae26-bb07ca6fe2f9",
  session_clinic_initial_invitation_rt5: nil,
  session_clinic_subsequent_invitation_rt5: nil,
  session_school_reminder: "cc4a7f89-d260-461c-80f0-7e6e9af75e7a",
  vaccination_administered: "395a3ea1-df07-4dd6-8af1-64cc597ef383",
  vaccination_already_had: "fab1e355-bde1-47d5-835c-103bfd232b93",
  vaccination_not_administered: "aae061e0-b847-4d4c-a87a-12508f95a302"
}.freeze

# Here we track email and SMS templates that we used to send but no longer
# do. We need these to be able to display the names of the templates.
GOVUK_NOTIFY_UNUSED_TEMPLATES = {
  "16ae7602-c2b1-4731-bb74-fd4f1357feca" => :vaccination_administered_menacwy,
  "25473aa7-2d7c-4d1d-b0c6-2ac492f737c3" => :consent_confirmation_given,
  "4c616b22-eee8-423f-84d6-bd5710f744fd" => :vaccination_administered_td_ipv,
  "55d35c86-7365-406b-909f-1b7b78529ea8" =>
    :consent_school_subsequent_reminder_doubles,
  "6410145f-dac1-46ba-82f3-a49cad0f66a6" =>
    :consent_school_subsequent_reminder_hpv,
  "69612d3a-d6eb-4f04-8b99-ed14212e7245" => :vaccination_administered_hpv,
  "6aa04f0d-94c2-4a6b-af97-a7369a12f681" => :consent_school_request_hpv,
  "79e131b2-7816-46d0-9c74-ae14956dd77d" => :session_school_reminder,
  "7cda7ae5-99a2-4c40-9a3e-1863e23f7a73" => :consent_confirmation_given,
  "8835575d-be69-442f-846e-14d41eb214c7" =>
    :consent_school_initial_reminder_doubles,
  "ceefd526-d44c-4561-b0d2-c9ef4ccaba4f" =>
    :consent_school_initial_reminder_hpv,
  "e9aa7f0f-986f-49be-a1ee-6d1d1c13e9ec" => :consent_school_request_doubles,
  "fa3c8dd5-4688-4b93-960a-1d422c4e5597" => :triage_vaccination_will_happen,
  "6e4c514d-fcc9-4bc8-b7eb-e222a1445681" => :session_school_reminder
}.freeze
