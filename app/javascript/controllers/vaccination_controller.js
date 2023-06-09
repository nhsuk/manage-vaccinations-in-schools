import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="vaccinations"
export default class extends Controller {
  static targets = ["status"];
  static values = {
    id: String,
  };

  connect() {
    window.campaignVaccinations.then((data) => {
      if (data[this.idValue]["seen"] == "Vaccinated") {
        this.statusTarget.innerHTML = `<strong class="nhsuk-tag">Vaccinated</strong>`;
      } else {
        this.statusTarget.innerHTML = `<strong class="nhsuk-tag nhsuk-tag--grey">Not yet</strong>`;
      }
    });
  }
}
