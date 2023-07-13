import { Controller } from "@hotwired/stimulus";
import NhsukRadios from "nhsuk-frontend/packages/components/radios/radios";

// Connects to data-module="nhsuk-radios"
export default class extends Controller {
  connect() {
    this.addConditionalClassIfNeeded();
    this.promoteAriaControlsAttribute();

    NhsukRadios();
  }

  // We use govuk-frontend radio button HTML, which doesn't use a --conditional
  // modifier on the root element. NHSUK Radios require this in order to set up
  // and initialise.
  addConditionalClassIfNeeded() {
    if (!this.element.querySelectorAll(".nhsuk-radios__conditional").length)
      return;

    this.element.classList.add("nhsuk-radios--conditional");
  }

  // Promote data-aria-controls attribute to a aria-controls attribute as per
  // https://github.com/alphagov/govuk-frontend/blob/88fea750b5eb9c9d9f661405e68bfb59e59754b2/packages/govuk-frontend/src/govuk/components/radios/radios.mjs#L33-L34
  promoteAriaControlsAttribute() {
    const $inputs = this.element.querySelectorAll('input[type="radio"]');

    $inputs.forEach(($input) => {
      const targetId = $input.getAttribute("data-aria-controls");

      // Skip radios without data-aria-controls attributes, or where the
      // target element does not exist.
      if (!targetId || !document.getElementById(targetId)) {
        return;
      }

      // Promote the data-aria-controls attribute to a aria-controls attribute
      // so that the relationship is exposed in the AOM
      $input.setAttribute("aria-controls", targetId);
      $input.removeAttribute("data-aria-controls");
    });
  }
}
