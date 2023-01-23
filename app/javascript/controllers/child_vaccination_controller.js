import { Controller } from "@hotwired/stimulus";

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
  static values = {
    url: String,
  };

  initialize() {
    this.childVaccination = fetch(this.urlValue).then((response) => {
      return response.json();
    });
  }

  connect() {
    this.childVaccination.then((data) => {
      this.fullNameTarget.textContent = data["full_name"];
      this.sexTarget.textContent = data["sex"];
      this.dobTarget.textContent = data["dob"];
      this.consentTarget.textContent = data["consent"];
      this.gpTarget.textContent = data["gp"];
      this.nhsNumberTarget.textContent = data["nhs_number"];
      this.screeningTarget.textContent = data["screening"];
    });
  }
}
