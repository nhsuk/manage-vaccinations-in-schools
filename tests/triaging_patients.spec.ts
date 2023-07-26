import { test, expect } from "@playwright/test";
import { patientExpectations } from "./example_data";
import {
  init_page as init_shared_steps_page,
  given_the_app_is_setup,
  when_i_click_on_the_tab,
  when_i_click_on_the_patient,
  when_i_click_on_the_option,
} from "./shared_steps";

let p = null;

// Needs state transitions to be added to controller actions
test("Triaging patients", async ({ page }) => {
  p = page;
  await init_shared_steps_page(page);

  await given_the_app_is_setup();
  await when_i_go_to_the_triage_page_for_the_first_session();

  // Triage - start triage but without outcome
  await when_i_click_on_the_tab("Needs triage (2)");
  await when_i_click_on_the_patient("Caridad Sipes");
  await when_i_enter_the_note("Unable to reach mother");
  await when_i_click_on_the_option("Keep in triage");
  await when_i_click_on_the_submit_button();
  await when_i_click_on_the_tab("Needs triage (2)");
  await then_i_should_see_a_row_for_the_patient("Caridad Sipes", {
    tab: "Needs triage (2)",
    action: "Triage started",
  });

  // Triage - ready to vaccinate
  await when_i_click_on_the_patient("Caridad Sipes");
  await when_i_enter_the_note("Reached mother, should be able to proceed");
  await when_i_click_on_the_option("Ready to vaccinate");
  await when_i_click_on_the_submit_button();
  await when_i_click_on_the_tab("Triage complete (3)");
  await then_i_should_see_a_row_for_the_patient("Caridad Sipes", {
    tab: "Triage complete (3)",
    action: "Vaccinate",
  });
});

async function when_i_go_to_the_triage_page_for_the_first_session() {
  await p.goto("/sessions/1");
  await p.getByRole("link", { name: "Triage" }).click();
}

async function when_i_enter_the_note(note) {
  await p.getByLabel("Triage notes").type(note);
}

async function when_i_click_on_the_submit_button() {
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function then_i_should_see_a_row_for_the_patient(name, attributes) {
  const patient = { ...patientExpectations[name], ...attributes };
  const id = patient.tab.toLowerCase().replace(/ /g, "-").replace(/[()]/g, "");
  const row = p.locator(`#${id} tr`, { hasText: name });

  await expect(row).toBeVisible();
  await expect(row).toContainText(patient.action);
}
