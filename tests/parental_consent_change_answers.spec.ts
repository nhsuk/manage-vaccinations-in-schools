import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Parental consent change answers", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_to_the_consent_start_page();
  await then_i_see_the_consent_start_page();

  await when_i_fill_in_the_all_the_consent_questions();
  await then_i_see_the_consent_confirm_page();

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
  await then_i_see_the_confirmation_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_consent_start_page() {
  await p.goto("/sessions/2/consents/start");
}

async function then_i_see_the_consent_start_page() {
  await expect(p.locator("h1")).toContainText(
    "Give or refuse consent for a flu vaccination",
  );
}

async function when_i_fill_in_the_all_the_consent_questions() {
  await p.goto("/random_consent_form?session_id=2");
}

async function then_i_see_the_consent_confirm_page() {
  await expect(p.locator("h1")).toContainText("Check your answers and confirm");
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

async function then_i_see_the_confirmation_page() {
  await expect(p.locator("h1")).toContainText(
    "Joe Test will get their nasal flu vaccination at school",
  );
}
