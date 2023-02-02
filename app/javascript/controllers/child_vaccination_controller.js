import { Controller } from "@hotwired/stimulus";

function parseIdsFromURL(url) {
  const [_, campaignId, childId] = url.match(
    "/campaigns/(\\d+)/children/(\\d+)$"
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
  ];

  async connect() {
    const { campaignId, childId } = parseIdsFromURL(window.location.href);
    const response = await fetch(`/campaigns/${campaignId}/children.json`);
    const json = await response.json();
    const child = json[childId];

    this.fullNameTarget.textContent = child["full_name"];
    this.sexTarget.textContent = child["sex"];
    this.dobTarget.textContent = child["dob"];
    this.consentTarget.textContent = child["consent"];
    this.gpTarget.textContent = child["gp"];
    this.nhsNumberTarget.textContent = child["nhs_number"];
    this.screeningTarget.textContent = child["screening"];
  }
}
