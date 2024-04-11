import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

// Needs state transitions to be added to controller actions
test("Triage", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();
  await when_i_go_to_the_triage_page();

  // Triage - start triage but without outcome
  await when_i_click_on_a_patient();
  await and_i_enter_a_note_and_save_triage();
  await then_the_patient_should_still_be_in_triage();

  // Triage - ready to vaccinate
  await when_i_click_on_a_patient();
  await and_i_enter_a_note_and_select_ready_to_vaccinate();
  await and_i_click_on_the_triage_complete_tab();
  await then_the_patient_should_be_in_ready_to_vaccinate();

  await when_i_click_on_a_patient();
  await then_i_should_see_triage_notes();

  // Triage - not ready to vaccinate
  await given_i_click_on_back();
  await when_i_click_on_the_triage_needed_tab();
  await and_i_click_on_another_patient();
  await and_i_enter_a_note_and_select_do_not_vaccinate();
  await then_i_should_be_back_on_the_triage_needed_tab();
  await and_i_should_not_see_the_other_patient();

  await when_i_click_on_the_triage_complete_tab();
  await then_i_should_see_the_other_patient();

  await when_i_click_on_the_other_patient();
  await then_i_should_see_the_do_not_vaccinate_triage_notes();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_triage_page() {
  await p.goto("/sessions/1/triage");
}

async function when_i_click_on_a_patient() {
  await p.getByRole("link", { name: fixtures.patientThatNeedsTriage }).click();
}

async function and_i_enter_a_note_and_save_triage() {
  await p.getByLabel("Triage notes").fill("Unable to reach mother");
  await p.getByRole("radio", { name: "Keep in triage" }).click();
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function then_the_patient_should_still_be_in_triage() {
  await expect(
    p.getByRole("row", { name: fixtures.patientThatNeedsTriage }),
  ).toBeVisible();
}

async function and_i_enter_a_note_and_select_ready_to_vaccinate() {
  await p.getByLabel("Triage notes").fill("Reached mother, able to proceed");
  await p.getByRole("radio", { name: "Yes, it’s safe to vaccinate" }).click();
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function when_i_click_on_the_triage_complete_tab() {
  await p.getByRole("link", { name: "Triage completed" }).click();
}
const and_i_click_on_the_triage_complete_tab =
  when_i_click_on_the_triage_complete_tab;

async function then_the_patient_should_be_in_ready_to_vaccinate() {
  await expect(
    p.getByRole("row", { name: fixtures.patientThatNeedsTriage }),
  ).toBeVisible();
}

async function then_i_should_see_triage_notes() {
  const today = new Date();
  // Partial test. We're going to avoid wrestling with DateTimeFormat to get
  // this 100% right, it's not useful for this test.
  const formattedDate = today.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });

  // Note 1
  await expect(
    p.locator("div.nhsuk-card", {
      has: p.locator('h2:has-text("Triage notes")'),
    }),
  ).toHaveText(
    new RegExp(`Unable to reach mother\\s*Nurse Joy, ${formattedDate}`),
  );

  // Note 2
  await expect(
    p.locator("div.nhsuk-card", {
      has: p.locator('h2:has-text("Triage notes")'),
    }),
  ).toHaveText(
    new RegExp(
      `Reached mother, able to proceed\\s*Nurse Joy, ${formattedDate}`,
    ),
  );
}

async function given_i_click_on_back() {
  await p.click("text=Back");
}

async function when_i_click_on_the_triage_needed_tab() {
  await p.getByRole("tab", { name: /Triage needed/ }).click();
}

async function when_i_click_on_the_other_patient() {
  await p
    .getByRole("link", { name: fixtures.secondPatientThatNeedsTriage })
    .click();
}
const and_i_click_on_another_patient = when_i_click_on_the_other_patient;

async function and_i_enter_a_note_and_select_do_not_vaccinate() {
  await p
    .getByLabel("Triage notes")
    .fill("Father adament he does not want to vaccinate");
  await p.getByRole("radio", { name: "Do not vaccinate" }).click();
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function then_i_should_be_back_on_the_triage_needed_tab() {
  await expect(p.getByRole("tab", { name: /Triage needed/ })).toBeVisible();
}

async function and_i_should_not_see_the_other_patient() {
  await expect(
    p.getByRole("link", { name: fixtures.secondPatientThatNeedsTriage }),
  ).not.toBeVisible();
}

async function then_i_should_see_the_other_patient() {
  await expect(
    p.getByRole("link", { name: fixtures.secondPatientThatNeedsTriage }),
  ).toBeVisible();
}

async function then_i_should_see_the_do_not_vaccinate_triage_notes() {
  const today = new Date();
  // Partial test. We're going to avoid wrestling with DateTimeFormat to get
  // this 100% right, it's not useful for this test.
  const formattedDate = today.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });

  await expect(
    p.locator("div.nhsuk-card", {
      has: p.locator('h2:has-text("Triage notes")'),
    }),
  ).toHaveText(
    new RegExp(
      `Father adament he does not want to vaccinate\\s*Nurse Joy, ${formattedDate}`,
    ),
  );
}
