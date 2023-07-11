import { Controller } from "@hotwired/stimulus";
import { ErrorSummary } from "govuk-frontend";

// Connects to data-module="govuk-error-summary"
export default class extends Controller {
  connect() {
    new ErrorSummary(this.element).init();
  }
}
