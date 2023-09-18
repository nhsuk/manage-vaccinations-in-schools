import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

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
  await and_i_click_on_the_ready_to_vaccinate_tab();
  await then_the_patient_should_be_in_ready_to_vaccinate();
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
  await p.getByRole("link", { name: "Caridad Sipes" }).click();
}

async function and_i_enter_a_note_and_save_triage() {
  await p.getByLabel("Triage notes").type("Unable to reach mother");
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function then_the_patient_should_still_be_in_triage() {
  await expect(
    p.getByRole("row", {
      name: "Caridad Sipes Notes need triage Triage started",
    }),
  ).toBeVisible();
}

async function and_i_enter_a_note_and_select_ready_to_vaccinate() {
  await p.getByLabel("Triage notes").type("Reached mother, able to proceed");
  await p.getByRole("radio", { name: "Ready to vaccinate" }).click();
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function and_i_click_on_the_ready_to_vaccinate_tab() {
  await p.getByRole("tab", { name: "Triage complete" }).click();
}

async function then_the_patient_should_be_in_ready_to_vaccinate() {
  await expect(
    p.getByRole("row", {
      name: "Caridad Sipes Notes need triage Vaccinate",
    }),
  ).toBeVisible();
}
