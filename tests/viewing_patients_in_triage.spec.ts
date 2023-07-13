import { test, expect } from "@playwright/test";
import { patient_expectations, example_patient } from "./example_data";
import {
  init_page as init_shared_steps_page,
  given_the_app_is_setup,
  when_i_click_on_the_tab,
  when_i_click_on_the_patient,
  then_i_should_be_on_the_tab,
  then_i_should_see_a_banner_for_the_patient,
  capitalise,
  humanise,
} from "./shared_steps";

export let p = null;

test("Viewing patients", async ({ page }) => {
  p = page;
  await init_shared_steps_page(page);

  await given_the_app_is_setup();

  await when_i_go_to_the_triage_page_for_the_first_session();
  await then_i_should_see_the_triage_index_page();
  await then_i_should_see_the_correct_breadcrumbs();
  await then_i_should_be_on_the_tab("Needs triage");

  for (let name in patient_expectations) {
    if (!patient_expectations[name].tab) continue;

    await when_i_click_on_the_tab(patient_expectations[name].tab);
    await then_i_should_see_a_triage_row_for_the_patient(name);

    await when_i_click_on_the_patient(name);
    await then_i_should_see_the_triage_page_for_the_patient(name);
    await then_i_should_see_a_banner_for_the_patient(name);
    await and_i_should_see_the_consent_section_for_the_patient(name);
    await and_i_should_see_health_question_responses_if_present(name);

    await when_i_go_back_to_the_triage_index_page();
    await then_i_should_see_the_triage_index_page();
  }
});

export async function when_i_go_to_the_triage_page_for_the_first_session() {
  await p.goto("/sessions/1");
  await p.getByRole("link", { name: "Triage" }).click();
}

export async function when_i_go_back_to_the_triage_index_page() {
  await p.getByRole("link", { name: "Back to triage" }).click();
}

export async function when_i_enter_the_note(note) {
  await p.getByLabel("Triage notes").type(note);
}

export async function when_i_clear_the_note() {
  await p.getByLabel("Triage notes").clear();
}

export async function when_i_click_on_the_submit_button() {
  await p.getByRole("button", { name: "Save triage" }).click();
}

export async function then_i_should_see_the_triage_index_page() {
  await expect(p.locator("h1")).toContainText("Triage");
}

export async function then_i_should_see_the_correct_breadcrumbs() {
  await expect(p.locator(".nhsuk-breadcrumb__item:last-of-type")).toContainText(
    "HPV session at St Andrew's Benn CofE (Voluntary Aided) Primary School",
  );
}

export async function then_i_should_see_a_triage_row_for_the_patient(
  name,
  attributes = {},
) {
  const patient = { ...patient_expectations[name], ...attributes };
  const id = patient.tab.toLowerCase().replace(/ /g, "-");
  const row = p.locator(`#${id} tr`, { hasText: name });

  if (patient.triage_reasons) {
    for (let reason of patient.triage_reasons) {
      await expect(row, `[${name}] Triage reason`).toContainText(reason);
    }
  }

  await expect(row, `[${name}] Status text`).toContainText(patient.action);

  const colourClass = "nhsuk-tag--" + patient.action_colour;
  await expect(
    row.locator("td:nth-child(3) div"),
    `[${name}] Status colour`,
  ).toHaveClass(new RegExp(colourClass));
}

export async function then_i_should_see_the_triage_page_for_the_patient(name) {
  await expect(p.locator("h1"), `[${name}] Triage page title`).toContainText(
    name,
  );
}

export async function and_i_should_see_the_consent_section_for_the_patient(
  name,
) {
  const consentResponse = example_patient(name).consent;

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

export async function and_i_should_see_health_question_responses_if_present(
  name,
) {
  let consent = example_patient(name).consent;

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
