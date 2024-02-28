import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Parental consent change answers", async ({ page }) => {
  p = page;

  // Health questions contain Yes answers
  await given_the_app_is_setup();
  await when_i_go_to_a_prefilled_consent_form();
  await then_i_see_the_consent_confirm_page();

  await when_i_change_my_parental_relationship_to_other();
  await then_i_see_the_parental_responsibility_error();

  await when_i_refuse_parental_responsibility();
  await then_i_see_the_cannot_consent_responsibility_page();

  await when_i_accept_parental_responsibility();
  await then_i_see_the_consent_confirm_page();

  await when_i_change_my_parental_relationship_to_dad();
  await then_i_see_the_consent_confirm_page();

  await when_i_change_the_patients_name();
  await then_i_see_the_updated_name();

  await when_i_click_on_the_change_link_of_the_first_answer();
  await then_i_see_the_health_question();

  await when_i_change_my_answer_to_yes_for_the_asthma_question();
  await then_i_see_the_first_follow_up_question();

  await when_i_answer_yes_to_the_follow_up_question_and_continue();
  await then_i_see_the_second_follow_up_question();

  await when_i_answer_yes_to_the_follow_up_question_and_continue();
  await then_i_see_the_consent_confirm_page();
  await and_i_see_the_answer_i_changed_is_yes();

  await when_i_click_the_confirm_button();
  await then_i_see_the_needs_triage_confirmation_page();

  // Offer an injection instead
  await when_i_go_to_a_prefilled_consent_form();
  await then_i_see_the_consent_confirm_page();

  await when_i_change_my_consent();
  await and_say_the_reason_is_that_the_vaccine_contains_gelatine();
  await and_agree_to_be_contacted_by_a_nurse();
  await then_i_see_the_consent_confirm_page();

  await when_i_click_the_confirm_button();
  await then_i_see_the_injection_confirmation_page();

  // Consent refused
  await when_i_go_to_a_prefilled_consent_form();
  await then_i_see_the_consent_confirm_page();

  await when_i_change_my_consent();
  await and_say_the_reason_is_that_the_vaccine_contains_gelatine();
  await and_do_not_agree_to_be_contacted_by_a_nurse();
  await then_i_see_the_consent_confirm_page();

  await when_i_click_the_confirm_button();
  await then_i_see_the_refused_confirmation_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_a_prefilled_consent_form() {
  await p.goto("/random_consent_form?session_id=2");
}

async function then_i_see_the_consent_confirm_page() {
  await expect(p.locator("h1")).toContainText("Check your answers and confirm");
}

async function then_i_see_the_updated_name() {
  expect(p.getByText("Joe Test")).toBeVisible();
}

async function when_i_change_the_patients_name() {
  await p
    .getByRole("link", { name: "Change child’s name", exact: true })
    .click();
  await p.getByLabel("First name").fill("Joe");
  await p.getByLabel("Last name").fill("Test");
  await p.getByRole("button", { name: "Continue" }).click();
}

async function when_i_click_on_the_change_link_of_the_first_answer() {
  await p
    .getByRole("link", {
      name: "Change your answer to health question 1",
      exact: true,
    })
    .click();
}

async function then_i_see_the_health_question() {
  await expect(p.locator("h1")).toContainText(
    "Has your child been diagnosed with asthma?",
  );
}

async function when_i_change_my_answer_to_yes_for_the_asthma_question() {
  await p.getByRole("radio", { name: "Yes" }).click();
  await p.getByLabel("Give details").fill("He has had asthma since he was 2");
  await p.getByRole("button", { name: "Continue" }).click();
}

async function when_i_answer_yes_to_the_follow_up_question_and_continue() {
  await p.getByRole("radio", { name: "Yes" }).click();
  await p.getByLabel("Give details").fill("Follow up details");
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_first_follow_up_question() {
  await expect(p.locator("h1")).toContainText(
    "Have they taken oral steroids in the last 2 weeks?",
  );
}

async function then_i_see_the_second_follow_up_question() {
  await expect(p.locator("h1")).toContainText(
    "Have they been admitted to intensive care for their asthma?",
  );
}
async function and_i_see_the_answer_i_changed_is_yes() {
  await expect(
    p.getByText("Yes – He has had asthma since he was 2"),
  ).toBeVisible();
}

async function when_i_click_the_confirm_button() {
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_the_needs_triage_confirmation_page() {
  await expect(p.locator("h1")).toContainText(
    "You’ve given consent for your child to get a flu vaccination",
  );
}

async function when_i_change_my_consent() {
  await p.getByRole("link", { name: "Change consent", exact: true }).click();
  await p.getByRole("radio", { name: "No" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function and_say_the_reason_is_that_the_vaccine_contains_gelatine() {
  await p
    .getByRole("radio", { name: "Vaccine contains gelatine from pigs" })
    .click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function and_agree_to_be_contacted_by_a_nurse() {
  await p.getByRole("radio", { name: "Yes" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_injection_confirmation_page() {
  await expect(p.locator("h1")).toContainText(
    "Your child will not get a nasal flu vaccination",
  );
  await expect(
    p.locator("p", { hasText: "having an injection instead" }),
  ).toBeVisible();
}

async function and_do_not_agree_to_be_contacted_by_a_nurse() {
  await p.getByRole("radio", { name: "No" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_refused_confirmation_page() {
  await expect(p.locator("h1")).toContainText(
    "Your child will not get a nasal flu vaccination",
  );
  await expect(
    p.locator("p", { hasText: "having an injection instead" }),
  ).not.toBeVisible();
}

async function when_i_change_my_parental_relationship_to_other() {
  await p
    .getByRole("link", { name: "Change your relationship", exact: true })
    .click();
  await p.getByRole("radio", { name: "Other" }).click();
  await p.getByLabel("Relationship to the child").fill("Granddad");
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_parental_responsibility_error() {
  await expect(p.locator(".nhsuk-error-summary")).toContainText(
    "You need parental responsibility to give consent",
  );
}

async function when_i_accept_parental_responsibility() {
  await p.getByRole("link", { name: "Back" }).click();
  await p.getByRole("radio", { name: "Other" }).click();
  await p.getByLabel("Relationship to the child").fill("Granddad");
  await p.getByRole("radio", { name: "Yes" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
  // BUG: The page should be the consent confirm page, but because we
  // encountered a validation error, the skip_to_confirm flag gets lost and we
  // end up on the next page in the wizard.
  for (let i = 0; i < 12; i++) {
    await p.getByRole("button", { name: "Continue" }).click();
  }
}

async function when_i_change_my_parental_relationship_to_dad() {
  await p
    .getByRole("link", { name: "Change your relationship", exact: true })
    .click();
  await p.getByRole("radio", { name: "Dad" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function when_i_refuse_parental_responsibility() {
  await p.getByRole("radio", { name: "No" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_cannot_consent_responsibility_page() {
  await expect(p.locator("h1")).toContainText(
    "You cannot give or refuse consent",
  );
}
