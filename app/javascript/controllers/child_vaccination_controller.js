import { Controller } from "@hotwired/stimulus";

function parseIdsFromURL(url) {
  const [_, campaignId, childId] = url.match(
    "/sessions/(\\d+)/vaccinations/(\\d+)$",
  );
  return { campaignId, childId };
}

// Connects to data-controller="child-vaccination"
export default class extends Controller {
  static targets = [
    "fullName",
    "sex",
    "dob",
    "consent",
    "gp",
    "nhsNumber",
    "screening",
    "form",
  ];

  async connect() {
    const { campaignId, childId } = parseIdsFromURL(window.location.href);
    const response = await fetch(`/sessions/${campaignId}/vaccinations.json`);
    const json = await response.json();
    const child = json[childId];

    this.fullNameTarget.textContent = child["full_name"];
    this.dobTarget.textContent = child["dob"];
    this.gpTarget.textContent = child["gp"];
    this.nhsNumberTarget.textContent = child["nhs_number"];
    this.formTarget.action = this.formTarget.action.replace(":id", childId);
  }
}
