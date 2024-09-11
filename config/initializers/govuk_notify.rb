# frozen_string_literal: true

GOVUK_NOTIFY_EMAIL_TEMPLATES = {
  confirmation_the_hpv_vaccination_didnt_happen:
    "130fe52a-014a-45dd-9f53-8e65c1b8bb79",
  confirmation_the_hpv_vaccination_has_taken_place:
    "8a65d7b5-045c-4f26-8f76-6e593c14cb6d",
  hpv_session_consent_reminder: "ceefd526-d44c-4561-b0d2-c9ef4ccaba4f",
  hpv_session_consent_request: "6aa04f0d-94c2-4a6b-af97-a7369a12f681",
  hpv_session_session_reminder: "79e131b2-7816-46d0-9c74-ae14956dd77d",
  parental_consent_confirmation: "7cda7ae5-99a2-4c40-9a3e-1863e23f7a73",
  parental_consent_confirmation_injection:
    "4d09483a-8181-4acb-8ba3-7abd6c8644cd",
  parental_consent_confirmation_needs_triage:
    "604ee667-c996-471e-b986-79ab98d0767c",
  parental_consent_confirmation_refused: "5a676dac-3385-49e4-98c2-fc6b45b5a851",
  parental_consent_give_feedback: "1250c83b-2a5a-4456-8922-657946eba1fd",
  triage_vaccination_will_happen: "fa3c8dd5-4688-4b93-960a-1d422c4e5597",
  triage_vaccination_wont_happen: "d1faf47e-ccc3-4481-975b-1ec34211a21f"
}.freeze

GOVUK_NOTIFY_TEXT_TEMPLATES = {
  consent_given: "25473aa7-2d7c-4d1d-b0c6-2ac492f737c3",
  consent_refused: "eb34f3ab-0c58-4e56-b6b1-2c179270dfc3",
  consent_reminder: "ee3d36b1-4682-4eb0-a74a-7e0f6c9d0598",
  consent_request: "03a0d572-ca5b-417e-87c3-838872a9eabc",
  session_reminder: "6e4c514d-fcc9-4bc8-b7eb-e222a1445681",
  vaccination_didnt_happen: "aae061e0-b847-4d4c-a87a-12508f95a302",
  vaccination_has_taken_place: "69612d3a-d6eb-4f04-8b99-ed14212e7245"
}.freeze
