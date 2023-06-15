import { test, expect } from "@playwright/test";

test("Performing triage", async ({ page }) => {
  await page.goto("/reset");

  await page.goto("/sessions/1");
  await page.getByRole("link", { name: "Triage" }).click();

  await expect(page.locator("h1")).toContainText("Triage");

  const patients = [
    {
      row: 1,
      name: "Aaron Pfeffer",
      note: "",
      status: "To do",
      class: "nhsuk-tag--grey",
    },
    {
      row: 2,
      name: "Alaia Lakin",
      note: "",
      status: "Ready for session",
      class: "nhsuk-tag--green",
      icon: "nhsuk-icon__tick",
    },
    {
      row: 3,
      name: "Aliza Kshlerin",
      note: "Notes from nurse",
      status: "Ready for session",
      class: "nhsuk-tag--green",
      icon: "nhsuk-icon__tick",
    },
    {
      row: 4,
      name: "Amalia Wiza",
      note: "",
      status: "Do not vaccinate",
      class: "nhsuk-tag--red",
      icon: "nhsuk-icon__cross",
    },
    {
      row: 5,
      name: "Amara Klein",
      note: "Notes from nurse",
      status: "Do not vaccinate",
      class: "nhsuk-tag--red",
      icon: "nhsuk-icon__cross",
    },
    {
      row: 6,
      name: "Amara Rodriguez",
      note: "",
      status: "Needs follow up",
      class: "nhsuk-tag--blue",
    },
  ];

  for (const patient of patients) {
    await expect(
      page.locator(`#patients tr:nth-child(${patient.row}) td:first-child`),
      `Name for patient row: ${patient.row} name: ${patient.name}`
    ).toContainText(patient.name);

    if (patient.note) {
      await expect(
        page.locator(`#patients tr:nth-child(${patient.row}) td:nth-child(2)`),
        `Note for patient row: ${patient.row} name: ${patient.name}`
      ).toContainText(patient.note);
    } else {
      await expect(
        page.locator(`#patients tr:nth-child(${patient.row}) td:nth-child(2)`),
        `Empty note patient row: ${patient.row} name: ${patient.name}`
      ).toBeEmpty();
    }
    await expect(
      page.locator(`#patients tr:nth-child(${patient.row}) td:nth-child(3)`),
      `Status text for patient row: ${patient.row} name: ${patient.name}`
    ).toContainText(patient.status);

    await expect(
      page.locator(
        `#patients tr:nth-child(${patient.row}) td:nth-child(3) div`
      ),
      `Status colour for patient row: ${patient.row} name: ${patient.name}`
    ).toHaveClass(new RegExp(patient.class));

    if (patient.icon) {
      await expect(
        page.locator(
          `#patients tr:nth-child(${patient.row}) td:nth-child(3) div svg`
        ),
        `Status icon patient row: ${patient.row} name: ${patient.name}`
      ).toHaveClass(new RegExp(patient.icon));
    } else {
      expect(
        await page
          .locator(
            `#patients tr:nth-child(${patient.row}) td:nth-child(3) div svg`
          )
          .count(),
        `No status icon for patient row: ${patient.row} name: ${patient.name}`
      ).toEqual(0);
    }
  }
});
