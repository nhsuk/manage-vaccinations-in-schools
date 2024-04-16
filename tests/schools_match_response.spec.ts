import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("School - match response", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_go_to_the_session_page();
  await and_i_click_on_the_check_consent_responses_link();
  await and_a_specific_cohort_record_is_not_present();

  await and_i_click_on_the_unmatched_responses_link();
  await then_i_am_on_the_unmatched_responses_page();

  await when_i_click_on_an_unmatched_response();
  await then_i_am_on_the_consent_form_page();
  await and_i_can_see_the_matching_criteria();

  await when_i_select_a_child_record();
  await and_i_review_the_match();
  await and_i_link_the_response_with_the_record();

  await then_i_am_on_the_unmatched_responses_page();
  await and_i_click_on_the_check_consent_responses_link();
  await and_the_matched_cohort_appears_in_the_consent_given_list();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_session_page() {
  await p.goto("/sessions/1");
}

async function and_i_click_on_the_check_consent_responses_link() {
  await p.getByRole("link", { name: "Check consent responses" }).click();
}

async function and_a_specific_cohort_record_is_not_present() {
  await p.getByRole("link", { name: "Given" }).click();
  await expect(
    p
      .locator(
        `//td[contains(., '${fixtures.cohortRecordChildNameForUnmatchedConsentForm}')]`,
      )
      .first(),
  ).not.toBeVisible();
}

async function and_i_click_on_the_unmatched_responses_link() {
  await p
    .getByRole("link", {
      name: /responses? need matching with records in the cohort/,
    })
    .click();
}

async function then_i_am_on_the_unmatched_responses_page() {
  await expect(
    p.getByRole("heading", { name: "Unmatched consent responses" }),
  ).toBeVisible();
}

async function when_i_click_on_an_unmatched_response() {
  const row = await p
    .locator(
      `//td[contains(., '${fixtures.unmatchedConsentFormParentName}')]/parent::tr`,
    )
    .first();
  if (row) {
    await row.getByRole("link", { name: "Find match" }).click();
  } else {
    throw new Error("Could not find unmatched consent response");
  }
}

async function then_i_am_on_the_consent_form_page() {
  await expect(
    p.getByRole("heading", {
      name: `Search for a child record`,
    }),
  ).toBeVisible();
}

async function and_i_can_see_the_matching_criteria() {
  const matchingCriteriaTable = await p.locator("details").first();
  await expect(matchingCriteriaTable).toBeVisible();
  await expect(matchingCriteriaTable).toHaveText(
    new RegExp(fixtures.unmatchedConsentFormParentName),
  );
  await expect(matchingCriteriaTable).toHaveText(
    new RegExp(fixtures.unmatchedConsentFormChildName),
  );
}

async function when_i_select_a_child_record() {
  const row = await p
    .locator(
      `//td[contains(., '${fixtures.cohortRecordChildNameForUnmatchedConsentForm}')]/parent::tr`,
    )
    .first();

  if (!row) {
    throw new Error("Could not find child record");
  } else {
    await row.getByRole("link", { name: "Select" }).click();
  }
}

async function and_i_review_the_match() {
  const header = await p.locator("h1").first();
  await expect(header).toHaveText(
    new RegExp(fixtures.unmatchedConsentFormParentName),
  );
  await expect(p.locator("table").first()).toHaveText(
    new RegExp(fixtures.unmatchedConsentFormChildName),
  );
}

async function and_i_link_the_response_with_the_record() {
  await p.getByRole("button", { name: "Link response with record" }).click();
}

async function and_the_matched_cohort_appears_in_the_consent_given_list() {
  await p.getByRole("link", { name: "Given" }).click();
  await expect(
    p
      .locator(
        `//td[contains(., '${fixtures.cohortRecordChildNameForUnmatchedConsentForm}')]`,
      )
      .first(),
  ).toBeVisible();
}
