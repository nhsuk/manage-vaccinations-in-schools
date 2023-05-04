import { Controller } from "@hotwired/stimulus";
import { getAll } from "../serviceworker/store";

// Connects to data-controller="vaccinations"
export default class extends Controller {
  static targets = ["status"];
  static values = {
    id: String,
  };

  async connect() {
    const reqs = await getAll("delayedRequests");
    const childId = this.idValue;

    if (reqs.find((req) => req.url.includes(`children/${childId}`))) {
      this.statusTarget.innerHTML = `<strong class="nhsuk-tag">Vaccinated</stong`;
    }
  }
}
