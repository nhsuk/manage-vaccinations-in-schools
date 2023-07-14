import { test, expect } from "@playwright/test";
import { patientExpectations, examplePatient } from "./example_data";
import {
  init_page as init_shared_steps_page,
  given_the_app_is_setup,
  when_i_click_on_the_tab,
  when_i_click_on_the_patient,
  when_i_click_on_the_option,
  capitalise,
  humanise,
} from "./shared_steps";

let p = null;

// Needs state transitions to be added to controller actions
test("Triaging patients", async ({ page }) => {
  p = page;
  await init_shared_steps_page(page);

  await given_the_app_is_setup();

  await when_i_go_to_the_triage_page_for_the_first_session();
  await when_i_click_on_the_tab("Needs triage");
  await when_i_click_on_the_patient("Blaine DuBuque");
  await when_i_enter_the_note("Notes from nurse");
  await when_i_click_on_the_option("Do not vaccinate");
  await when_i_click_on_the_submit_button();
  await when_i_click_on_the_tab("Triage complete");
  await then_i_should_see_a_row_for_the_patient("Blaine DuBuque", {
    tab: "Triage complete",
    action: "Do not vaccinate",
  });

  await when_i_click_on_the_tab("Needs triage");
  await when_i_click_on_the_patient("Caridad Sipes");
  await when_i_enter_the_note("Reached mother, should be able to proceed");
  await when_i_click_on_the_option("Ready to vaccinate");
  await when_i_click_on_the_submit_button();
  await when_i_click_on_the_tab("Triage complete");
  await then_i_should_see_a_row_for_the_patient("Caridad Sipes", {
    tab: "Triage complete",
    action: "Vaccinate",
  });
});

async function when_i_go_to_the_triage_page_for_the_first_session() {
  await p.goto("/sessions/1");
  await p.getByRole("link", { name: "Triage" }).click();
}

async function when_i_go_back_to_the_triage_index_page() {
  await p.getByRole("link", { name: "Back to triage" }).click();
}

async function when_i_enter_the_note(note) {
  await p.getByLabel("Triage notes").type(note);
}

async function when_i_clear_the_note() {
  await p.getByLabel("Triage notes").clear();
}

async function when_i_click_on_the_submit_button() {
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function then_i_should_see_the_triage_index_page() {
  await expect(p.locator("h1")).toContainText("Triage");
}

async function then_i_should_see_the_correct_breadcrumbs() {
  await expect(p.locator(".nhsuk-breadcrumb__item:last-of-type")).toContainText(
    "HPV session at St Andrew's Benn CofE (Voluntary Aided) Primary School",
  );
}

async function then_i_should_see_a_row_for_the_patient(name, attributes) {
  const patient = { ...patientExpectations[name], ...attributes };
  const id = patient.tab.toLowerCase().replace(/ /g, "-");
  const row = p.locator(`#${id} tr`, { hasText: name });

  await expect(row).toBeVisible();
  await expect(row).toContainText(patient.action);
}

async function and_i_should_see_the_consent_section_for_the_patient(name) {
  const consentResponse = examplePatient(name).consent;

  if (!consentResponse) {
    await expect(
      p.locator("#consent"),
      `[${name}] Consent response`,
    ).toContainText("No response given");
    return;
  }

  let parentRelationship;
  if (consentResponse.parentRelationship == "other")
    parentRelationship = consentResponse.parentRelationshipOther;
  else if (consentResponse.parentRelationship)
    parentRelationship = consentResponse.parentRelationship;
  parentRelationship = capitalise(parentRelationship);

  await expect(
    p.locator("#consent"),
    `[${name}] Consent response`,
  ).toContainText(
    capitalise(`${consentResponse.consent} by ${parentRelationship}`),
  );

  await expect(
    p.locator("#consent"),
    `[${name}] Consent parent relationship`,
  ).toContainText(`${parentRelationship} ${consentResponse.parentName}`);

  const route = capitalise(consentResponse.route);
  await expect(
    p.locator("#consent", `[${name}] Consent type should be be: ${route}`),
  ).toContainText(`Type of consent ${route}`);

  if (consentResponse.consent == "refused")
    await expect(
      p.locator("#consent"),
      `[${name}] Reason for refusal`,
    ).toContainText(
      `Reason for refusal ${humanise(consentResponse.reasonForRefusal)}`,
    );
}

async function and_i_should_see_health_question_responses_if_present(name) {
  let consent = examplePatient(name).consent;

  if (
    consent &&
    consent.healthQuestionResponses &&
    consent.healthQuestionResponses.length > 0
  ) {
    await expect(
      p.getByRole("heading", { name: "Health questions" }),
      `[${name}] Health questions heading`,
    ).toBeVisible();

    for (const example_question of consent["healthQuestionResponses"]) {
      await expect(
        p.locator("h3:text('" + example_question.question + "')"),
        `[${name}] Health question`,
      ).toContainText(example_question.question);

      if (example_question["response"].toLowerCase() == "yes") {
        await expect(
          p.locator("h3:text('" + example_question.question + "') + p"),
          `[${name}] Health question response`,
        ).toContainText("Yes – " + example_question.notes);
      } else {
        await expect(
          p.locator("h3:text('" + example_question.question + "') + p"),
          `[${name}] Health question response`,
        ).toContainText("No");
      }
    }
  } else {
    expect(
      await p.textContent("body"),
      `[${name}] No health questions`,
    ).not.toContain("Health questions");
  }
}
