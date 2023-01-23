import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="campaign"
export default class extends Controller {
  static values = {
    url: String,
  };

  initialize() {
    window.campaignVaccinations = fetch(this.urlValue).then((response) => {
      return response.json();
    });
  }

  connect() {}
}
