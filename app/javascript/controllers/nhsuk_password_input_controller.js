import { Controller } from "@hotwired/stimulus";
import { PasswordInput } from "govuk-frontend";

// Connects to data-controller="nhsuk-password-input"
export default class extends Controller {
  connect() {
    this.shimGovukClasses();
    new PasswordInput(this.element);
  }

  // The GOVUK Password Input JS relies on classes with govuk names. The form
  // builder generates ones with nhsuk names. This adds the missing classes so
  // we can use the govuk JS.
  shimGovukClasses() {
    this.element
      .querySelector(".nhsuk-js-password-input-input")
      .classList.add("govuk-js-password-input-input");
    this.element
      .querySelector(".nhsuk-js-password-input-toggle")
      .classList.add("govuk-js-password-input-toggle");
  }
}
