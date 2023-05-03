import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="vaccinations"
export default class extends Controller {
  static targets = ["status"];
  static values = {
    id: String,
  };

  connect() {}
}
