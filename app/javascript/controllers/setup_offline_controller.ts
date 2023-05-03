import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="setup-offline"
export default class extends Controller {
  static targets = ["form"];

  declare readonly formTarget: HTMLFormElement;

  connect() {
    this.formTarget.addEventListener("submit", this.handleSubmit.bind(this));
  }

  async handleSubmit(event: Event) {
    event.preventDefault();

    // TODO: Do async stuff

    this.formTarget.submit();
  }
}
