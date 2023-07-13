import { test, expect } from "@playwright/test";
import { example_patient } from "./example_data";

let p = null;

const patients = {
  "Blaine DuBuque": {
    tab: "Needs triage",
    action: "Triage",
    action_colour: "blue",
    banner_title: "Triage needed",
    triage_reasons: ["Notes need triage"],
    consent_response: "Given by",
    parent_relationship: "Mother",
  },
  "Caridad Sipes": {
    tab: "Needs triage",
    action: "Triage: follow up",
    action_colour: "aqua-green",
    banner_title: "Triage follow-up needed",
    triage_reasons: ["Notes need triage"],
  },
  "Jessika Lindgren": {
    tab: "Triage complete",
    action: "Vaccinate",
    action_colour: "purple",
  },
  "Kristal Schumm": {
    tab: "Triage complete",
    action: "Do not vaccinate",
    action_colour: "red",
    banner_title: "Do not vaccinate",
  },
  "Alexandra Sipes": {
    tab: "Get consent",
    action: "Get consent",
    action_colour: "yellow",
    banner_title: "No-one responded to our requests for consent",
  },
  "Ernie Funk": {
    tab: "No triage needed",
    action: /.*/,
    action_colour: "purple",
  },
  "Fae Skiles": {
    tab: "No triage needed",
    action: "Check refusal",
    action_colour: "orange",
  },
  "Man Swaniawski": {
    tab: "No triage needed",
    action: "Vaccinate",
    action_colour: "purple",
  },
};

test("Performing triage", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_to_the_triage_page_for_the_first_session();
  await then_i_should_see_the_triage_index_page();
  await then_i_should_see_the_correct_breadcrumbs();
  await then_i_should_be_on_the_tab("Needs triage");

  for (let name in patients) {
    if (!patients[name].tab) continue;

    await when_i_click_on_the_tab(patients[name].tab);
    await then_i_should_see_a_triage_row_for_the_patient(name);

    await when_i_click_on_the_patient(name);
    await then_i_should_see_the_triage_page_for_the_patient(name);
    await and_i_should_see_a_banner_for_the_patient(name);
    await and_i_should_see_the_consent_section_for_the_patient(name);
    await and_i_should_see_health_question_responses_if_present(name);

    await when_i_go_back_to_the_triage_index_page();
    await then_i_should_see_the_triage_index_page();
  }

  // await when_i_click_on_the_patient("Aaron Pfeffer");
  // await when_i_enter_the_note("Notes from nurse");
  // await when_i_click_on_the_option("Do not vaccinate");
  // await when_i_click_on_the_submit_button();
  // await then_i_should_see_a_triage_row_for_the_patient("Aaron Pfeffer", {
  //   note: "Notes from nurse",
  //   status: "Do not vaccinate",
  //   status_colour: "red",
  // });

  // await when_i_click_on_the_patient("Aaron Pfeffer");
  // await when_i_clear_the_note();
  // await when_i_click_on_the_option("Ready to vaccinate");
  // await when_i_click_on_the_submit_button();
  // await then_i_should_see_a_triage_row_for_the_patient("Aaron Pfeffer", {
  //   note: null,
  //   status: "Vaccinate",
  //   status_colour: "purple",
  // });
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_triage_page_for_the_first_session() {
  await p.goto("/sessions/1");
  await p.getByRole("link", { name: "Triage" }).click();
}

async function when_i_click_on_the_tab(name: string) {
  await p.getByRole("tab", { name: name, exact: true }).click();
}

async function when_i_click_on_the_patient(name) {
  await p.getByRole("link", { name: name }).click();
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

async function when_i_click_on_the_option(option) {
  await p.getByRole("radio", { name: option }).click();
}

async function when_i_click_on_the_submit_button() {
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function then_i_should_see_the_triage_index_page() {
  await expect(p.locator("h1")).toContainText("Triage");
}

async function then_i_should_see_the_correct_breadcrumbs() {
  await expect(p.locator(".nhsuk-breadcrumb__item:last-of-type")).toContainText(
    "HPV session at St Andrew's Benn CofE (Voluntary Aided) Primary School"
  );
}

async function then_i_should_be_on_the_tab(name: string) {
  await expect(p.getByRole("tab", { name: name, exact: true })).toHaveAttribute(
    "aria-selected",
    "true"
  );
}

async function then_i_should_see_a_triage_row_for_the_patient(
  name,
  attributes = {}
) {
  const patient = { ...patients[name], ...attributes };
  const id = patient.tab.toLowerCase().replace(/ /g, "-");
  const row = p.locator(`#${id} tr`, { hasText: name });

  if (patient.triage_reasons) {
    for (let reason of patient.triage_reasons) {
      await expect(row, `[${name}] Triage reason`).toContainText(reason);
    }
  }

  await expect(
    row,
    `[${name}] Status text should be ${patient.action}`
  ).toContainText(patient.action);

  const colourClass = "nhsuk-tag--" + patient.action_colour;
  await expect(
    // p.locator(`#${id} tr:nth-child(${patient.row}) td:nth-child(3) div`),
    row.locator("td:nth-child(3) div"),
    `[${name}] Status colour`
  ).toHaveClass(new RegExp(colourClass));
}

async function then_i_should_see_the_triage_page_for_the_patient(name) {
  await expect(p.locator("h1"), `[${name}] Triage page title`).toContainText(
    name
  );
}

async function and_i_should_see_a_banner_for_the_patient(name) {
  const patient = patients[name];
  const title = patient["banner_title"];
  const colourClass = "app-consent-banner--" + patient["action_colour"];
  const content = patient["banner_content"];

  if (title == null) return;

  await expect(
    p.locator(".app-consent-banner > span"),
    `[${name}] Banner title`
  ).toHaveText(title);
  await expect(
    p.locator("div.app-consent-banner"),
    `[${name}] Banner colour`
  ).toHaveClass(new RegExp(colourClass));

  if (content != null)
    for (let text of content) await expect(p.getByText(text)).toBeVisible();
}

async function and_i_should_see_the_consent_section_for_the_patient(name) {
  const patient = patients[name];
  const consentResponse = example_patient(name).consent;

  if (!consentResponse) {
    await expect(
      p.locator("#consent"),
      `[${name}] Consent response`
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
    `[${name}] Consent response`
  ).toContainText(
    capitalise(`${consentResponse.consent} by ${parentRelationship}`)
  );

  await expect(
    p.locator("#consent"),
    `[${name}] Consent parent relationship`
  ).toContainText(`${parentRelationship} ${consentResponse.parentName}`);

  const route = capitalise(consentResponse.route);
  await expect(
    p.locator("#consent", `[${name}] Consent type should be be: ${route}`)
  ).toContainText(`Type of consent ${route}`);

  if (consentResponse.consent == "refused")
    await expect(
      p.locator("#consent"),
      `[${name}] Reason for refusal`
    ).toContainText(
      `Reason for refusal ${humanise(consentResponse.reasonForRefusal)}`
    );
}

async function and_i_should_see_health_question_responses_if_present(name) {
  let consent = example_patient(name).consent;

  if (
    consent &&
    consent.healthQuestionResponses &&
    consent.healthQuestionResponses.length > 0
  ) {
    await expect(
      p.getByRole("heading", { name: "Health questions" }),
      `[${name}] Health questions heading`
    ).toBeVisible();

    for (const example_question of consent["healthQuestionResponses"]) {
      await expect(
        p.locator("h3:text('" + example_question.question + "')"),
        `[${name}] Health question`
      ).toContainText(example_question.question);

      if (example_question["response"].toLowerCase() == "yes") {
        await expect(
          p.locator("h3:text('" + example_question.question + "') + p"),
          `[${name}] Health question response`
        ).toContainText("Yes – " + example_question.notes);
      } else {
        await expect(
          p.locator("h3:text('" + example_question.question + "') + p"),
          `[${name}] Health question response`
        ).toContainText("No");
      }
    }
  } else {
    expect(
      await p.textContent("body"),
      `[${name}] No health questions`
    ).not.toContain("Health questions");
  }
}

function humanise(str: string) {
  return capitalise(str.replace(/_/g, " "));
}

function capitalise(str: string) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}
