import { test, expect } from "@playwright/test";

const patients = {
  "Aaron Pfeffer": {
    row: 1,
    note: "",
    status: "To do",
    class: "nhsuk-tag--grey",
    consent_response: "Given by",
    parent_name: "Betty Pfeffer",
    parent_email: "Betty_Pfeffer62@yahoo.com",
    parent_relationship: "Father",
    type_of_consent: "Paper",
  },
  "Alaia Lakin": {
    row: 2,
    note: "",
    status: "Ready for session",
    class: "nhsuk-tag--green",
    icon: "nhsuk-icon__tick",
    consent_response: "Given by",
    parent_name: "Garret Lakin",
    parent_email: "Garret57@hotmail.com",
    parent_relationship: "grandmother",
    type_of_consent: "Website",
  },
  "Aliza Kshlerin": {
    row: 3,
    note: "Notes from nurse",
    status: "Ready for session",
    class: "nhsuk-tag--green",
    icon: "nhsuk-icon__tick",
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
    icon: "nhsuk-icon__cross",
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
    icon: "nhsuk-icon__cross",
    consent_response: "Given by",
    parent_relationship: "Mother",
    parent_name: "Reese Klein",
    parent_email: "Reese9@gmail.com",
    type_of_consent: "Website",
  },
  "Amara Rodriguez": {
    row: 6,
    note: "",
    status: "Needs follow up",
    class: "nhsuk-tag--blue",
    consent_response: "Given by",
    parent_relationship: "Father",
    parent_name: "Lloyd Rodriguez",
    parent_email: "Lloyd.Rodriguez61@yahoo.com",
    type_of_consent: "Self consent",
  },
  "Amaya Sauer": {
    row: 7,
    note: "",
    status: "To do",
    class: "nhsuk-tag--grey",
    consent_response: "No response given",
  },
  "Annabel Morar": {
    row: 8,
    note: "",
    status: "To do",
    class: "nhsuk-tag--grey",
    consent_response: "Refused by",
    reason_for_refusal: "Personal choice",
    parent_relationship: "Father",
    parent_name: "Meggie Morar",
    parent_email: "Meggie19@hotmail.com",
    type_of_consent: "Website",
  },
};

test("Performing triage", async ({ page }) => {
  await page.goto("/reset");

  await page.goto("/sessions/1");
  await page.getByRole("link", { name: "Triage" }).click();

  await expect(page.locator("h1")).toContainText("Triage");

  await then_i_should_see_the_correct_breadcrumbs(page);
  await then_i_should_see_patients_with_their_triage_info(page);

  for (let name in patients) {
    await page.getByRole("link", { name: name }).click();
    await then_i_should_see_the_triage_page_for_the_patient(page, name);
    await page.getByRole("link", { name: "Back to triage" }).click();
  }
});

async function then_i_should_see_the_correct_breadcrumbs(page) {
  await expect(
    page.locator(".nhsuk-breadcrumb__item:last-of-type")
  ).toContainText(
    "HPV campaign at St Andrew's Benn CofE (Voluntary Aided) Primary School"
  );
}

async function then_i_should_see_patients_with_their_triage_info(page) {
  for (let name in patients) {
    let patient = patients[name];

    await expect(
      page.locator(`#patients tr:nth-child(${patient.row}) td:first-child`),
      `Name for patient row: ${patient.row} name: ${name}`
    ).toContainText(name);

    if (patient.note) {
      await expect(
        page.locator(`#patients tr:nth-child(${patient.row}) td:nth-child(2)`),
        `Note for patient row: ${patient.row} name: ${name}`
      ).toContainText(patient.note);
    } else {
      await expect(
        page.locator(`#patients tr:nth-child(${patient.row}) td:nth-child(2)`),
        `Empty note patient row: ${patient.row} name: ${name}`
      ).toBeEmpty();
    }
    await expect(
      page.locator(`#patients tr:nth-child(${patient.row}) td:nth-child(3)`),
      `Status text for patient row: ${patient.row} name: ${name}`
    ).toContainText(patient.status);

    await expect(
      page.locator(
        `#patients tr:nth-child(${patient.row}) td:nth-child(3) div`
      ),
      `Status colour for patient row: ${patient.row} name: ${name}`
    ).toHaveClass(new RegExp(patient.class));

    if (patient.icon) {
      await expect(
        page.locator(
          `#patients tr:nth-child(${patient.row}) td:nth-child(3) div svg`
        ),
        `Status icon patient row: ${patient.row} name: ${name}`
      ).toHaveClass(new RegExp(patient.icon));
    } else {
      expect(
        await page
          .locator(
            `#patients tr:nth-child(${patient.row}) td:nth-child(3) div svg`
          )
          .count(),
        `No status icon for patient row: ${patient.row} name: ${name}`
      ).toEqual(0);
    }
  }
}

async function then_i_should_see_the_triage_page_for_the_patient(page, name) {
  let patient = patients[name];
  await expect(page.locator("h1")).toContainText(name);

  let consentResponse = patient["consent_response"];

  await expect(page.locator("#consent")).toContainText(consentResponse);

  if (consentResponse == "No response given") return;

  let parentRelationship;
  if (patient["parent_relationship"]) {
    if (patient["parent_relationship"] == "Other")
      parentRelationship = patient["parent_relationship_other"];
    else parentRelationship = patient["parent_relationship"];
  }

  if (parentRelationship) consentResponse += " " + parentRelationship;
  await expect(page.locator("#consent")).toContainText(
    parentRelationship + " " + patient["parent_name"]
  );

  if (patient["type_of_consent"]) {
    await expect(page.locator("#consent")).toContainText(
      "Type of consent " + patient["type_of_consent"]
    );
  }

  if (patient["reason_for_refusal"]) {
    await expect(page.locator("#consent")).toContainText(
      "Reason for refusal " + patient["reason_for_refusal"]
    );
  }
}
