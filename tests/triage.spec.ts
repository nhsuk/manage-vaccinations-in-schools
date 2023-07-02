import { test, expect } from "@playwright/test";
import { example_patient } from "./example_data";

let p = null;

const patients = {
  "Aaron Pfeffer": {
    row: 1,
    note: "",
    status: "Vaccinate",
    class: "nhsuk-tag--purple",
    consent_response: "Given by",
    parent_name: "Betty Pfeffer",
    parent_email: "Betty_Pfeffer62@yahoo.com",
    parent_relationship: "Father",
    type_of_consent: "Paper",
  },
  "Alaia Lakin": {
    row: 2,
    note: "",
    status: "Vaccinate",
    class: "nhsuk-tag--purple",
    consent_response: "Given by",
    parent_name: "Garret Lakin",
    parent_email: "Garret57@hotmail.com",
    parent_relationship: "Grandmother",
    type_of_consent: "Website",
  },
  "Aliza Kshlerin": {
    row: 3,
    note: "Notes from nurse",
    status: "Vaccinate",
    class: "nhsuk-tag--purple",
    consent_response: "Given by",
    parent_name: "Georgianna Kshlerin",
    parent_email: "Georgianna.Kshlerin0@hotmail.com",
    parent_relationship: "Mother",
    type_of_consent: "Phone",
  },
  "Amalia Wiza": {
    row: 4,
    note: "",
    status: "Do not vaccinate",
    class: "nhsuk-tag--red",
    banner_colour_class: "app-consent-banner--red",
    banner_title: "Do not vaccinate",
    banner_content: [
      "The nurse has decided that Amalia Wiza should not be vaccinated",
    ],
    consent_response: "Given by",
    parent_relationship: "Mother",
    parent_name: "Jordi Wiza",
    parent_email: "Jordi.Wiza@yahoo.com",
    type_of_consent: "Website",
  },
  "Amara Klein": {
    row: 5,
    note: "Notes from nurse",
    status: "Do not vaccinate",
    class: "nhsuk-tag--red",
    consent_response: "Given by",
    parent_relationship: "Mother",
    parent_name: "Reese Klein",
    parent_email: "Reese9@gmail.com",
    type_of_consent: "Website",
  },
  "Amara Rodriguez": {
    row: 6,
    note: "",
    status: "Triage: follow up",
    class: "nhsuk-tag--aqua-green",
    banner_colour_class: "app-consent-banner--aqua-green",
    banner_title: "Triage follow-up needed",
    consent_response: "Given by",
    parent_relationship: "Father",
    parent_name: "Lloyd Rodriguez",
    parent_email: "Lloyd.Rodriguez61@yahoo.com",
    type_of_consent: "Self consent",
  },
  "Amaya Sauer": {
    row: 7,
    note: "",
    status: "Get consent",
    class: "nhsuk-tag--yellow",
    banner_colour_class: "app-consent-banner--yellow",
    banner_title: "No-one responded to our requests for consent",
    consent_response: "No response given",
  },
  "Annabel Morar": {
    row: 8,
    note: "",
    status: "Check refusal",
    class: "nhsuk-tag--orange",
    banner_colour_class: "app-consent-banner--orange",
    banner_title: "Their father has refused to give consent",
    consent_response: "Refused by",
    reason_for_refusal: "Personal choice",
    parent_relationship: "Father",
    parent_name: "Meggie Morar",
    parent_email: "Meggie19@hotmail.com",
    type_of_consent: "Website",
  },
  "Archie Simonis": {
    row: 9,
    note: "",
    status: "Triage",
    class: "nhsuk-tag--blue",
    banner_colour_class: "app-consent-banner--blue",
    banner_title: "Triage needed",
    banner_content: ["Notes need triage"],
    consent_response: "Given by",
    parent_relationship: "Mother",
    parent_name: "Erika Simonis",
    parent_email: "Erika54@hotmail.com",
    type_of_consent: "Website",
  },
};

test("Performing triage", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_to_the_triage_page_for_the_first_session();
  await then_i_should_see_the_triage_index_page();
  await then_i_should_see_the_correct_breadcrumbs();

  for (let name in patients) {
    await then_i_should_see_a_triage_row_for_the_patient(name);
    await when_i_click_on_the_patient(name);
    await then_i_should_see_the_triage_page_for_the_patient(name);
    await and_i_should_see_a_banner_for_the_patient(name);
    await and_i_should_see_the_consent_section_for_the_patient(name);
    await and_i_should_see_health_question_responses_if_present(name);

    await when_i_go_back_to_the_triage_index_page();
    await then_i_should_see_the_triage_index_page();
  }

  await when_i_click_on_the_patient("Aaron Pfeffer");
  await when_i_enter_the_note("Notes from nurse");
  await when_i_click_on_the_option("Do not vaccinate");
  await when_i_click_on_the_submit_button();
  await then_i_should_see_a_triage_row_for_the_patient("Aaron Pfeffer", {
    note: "Notes from nurse",
    status: "Do not vaccinate",
    class: "nhsuk-tag--red",
  });

  await when_i_click_on_the_patient("Aaron Pfeffer");
  await when_i_clear_the_note();
  await when_i_click_on_the_option("Ready to vaccinate");
  await when_i_click_on_the_submit_button();
  await then_i_should_see_a_triage_row_for_the_patient("Aaron Pfeffer", {
    note: null,
    status: "Vaccinate",
    class: "nhsuk-tag--purple",
  });
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_triage_page_for_the_first_session() {
  await p.goto("/sessions/1");
  await p.getByRole("link", { name: "Triage" }).click();
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

async function then_i_should_see_a_triage_row_for_the_patient(
  name,
  attributes = {}
) {
  let patient = { ...patients[name], ...attributes };

  await expect(
    p.locator(`#patients tr:nth-child(${patient.row}) td:first-child`),
    `Name for patient row: ${patient.row} name: ${name}`
  ).toContainText(name);

  await expect(
    p.locator(`#patients tr:nth-child(${patient.row}) td:nth-child(3)`),
    `Status text for patient row: ${patient.row} name: ${name}`
  ).toContainText(patient.status);

  await expect(
    p.locator(`#patients tr:nth-child(${patient.row}) td:nth-child(3) div`),
    `Status colour for patient row: ${patient.row} name: ${name}`
  ).toHaveClass(new RegExp(patient.class));
}

async function then_i_should_see_the_triage_page_for_the_patient(name) {
  let patient = patients[name];
  await expect(p.locator("h1")).toContainText(name);
}

async function and_i_should_see_a_banner_for_the_patient(name) {
  let patient = patients[name];
  let title = patient["banner_title"];
  let colourClass = patient["banner_colour_class"];
  let content = patient["banner_content"];

  if (colourClass != null)
    await expect(p.locator("div.app-consent-banner")).toHaveClass(
      new RegExp(colourClass)
    );

  if (title != null)
    await expect(p.locator(".app-consent-banner > span")).toHaveText(title);

  if (content != null)
    for (let text of content) await expect(p.getByText(text)).toBeVisible();
}

async function and_i_should_see_the_consent_section_for_the_patient(name) {
  let patient = patients[name];
  let consentResponse = patient["consent_response"];

  await expect(p.locator("#consent")).toContainText(consentResponse);

  if (consentResponse == "No response given") return;

  let parentRelationship;
  if (patient["parent_relationship"]) {
    if (patient["parent_relationship"] == "Other")
      parentRelationship = patient["parent_relationship_other"];
    else parentRelationship = patient["parent_relationship"];
  }

  if (parentRelationship) consentResponse += " " + parentRelationship;
  await expect(p.locator("#consent")).toContainText(
    parentRelationship + " " + patient["parent_name"]
  );

  if (patient["type_of_consent"]) {
    await expect(p.locator("#consent")).toContainText(
      "Type of consent " + patient["type_of_consent"]
    );
  }

  if (patient["reason_for_refusal"]) {
    await expect(p.locator("#consent")).toContainText(
      "Reason for refusal " + patient["reason_for_refusal"]
    );
  }
}

async function and_i_should_see_health_question_responses_if_present(name) {
  let patient = example_patient(name);
  let consent = patient["consent"];

  if (consent && consent["healthQuestionResponses"]) {
    await expect(
      p.getByRole("heading", { name: "Health questions" })
    ).toBeVisible();

    for (const example_question of consent["healthQuestionResponses"]) {
      await expect(
        p.locator("h3:text('" + example_question.question + "')")
      ).toContainText(example_question.question);

      if (example_question["response"].toLowerCase() == "yes") {
        await expect(
          p.locator("h3:text('" + example_question.question + "') + p")
        ).toContainText("Yes – " + example_question.notes);
      } else {
        await expect(
          p.locator("h3:text('" + example_question.question + "') + p")
        ).toContainText("No");
      }
    }
  } else {
    expect(await p.textContent("body")).not.toContain("Health questions");
  }
}
