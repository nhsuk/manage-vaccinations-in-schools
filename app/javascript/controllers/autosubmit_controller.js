import { Controller } from "@hotwired/stimulus";

// Connects to data-module="autosubmit"
export default class extends Controller {
  static targets = ["field", "reset", "filter"];

  connect() {
    this.filterTarget.style.display = "none";
    this.setResetButtonState();
  }

  submit() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
      this.setResetButtonState();
    }, 250);
  }

  setResetButtonState() {
    if (this.fieldTargets.every((f) => f.value === "")) {
      this.resetTarget.disabled = true;
    } else {
      this.resetTarget.disabled = false;
    }
  }
}
