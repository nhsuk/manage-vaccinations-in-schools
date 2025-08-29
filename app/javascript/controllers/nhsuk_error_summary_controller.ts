import { Controller } from "@hotwired/stimulus";
import { ErrorSummary } from "nhsuk-frontend";

// Connects to data-module="nhsuk-error-summary"
export default class extends Controller {
  connect() {
    this.shimFocusBehaviour();

    return new ErrorSummary(this.element);
  }

  // Because we're using the GOVUK Error Summary HTML, the server-rendered
  // element does not have tabindex=-1 set by default, which is required for
  // the initial focus to work. GOVUK Frontend also removes the tabindex
  // attribute on blur, as it doesn't need to be focused again.
  //
  // Based on https://github.com/alphagov/govuk-frontend/blob/91d0a5d8b694875b34eb4be52ecf155f8b3701d0/packages/govuk-frontend/src/govuk/components/error-summary/error-summary.mjs#L58-L64
  shimFocusBehaviour() {
    this.element.setAttribute("tabindex", "-1");

    this.element.addEventListener("blur", () => {
      this.element.removeAttribute("tabindex");
    });
  }
}
